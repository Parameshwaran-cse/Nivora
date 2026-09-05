import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/models.dart';

/// Firestore data access layer
/// All reads/writes go through this service for consistency

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  CollectionReference get _facultyRef => _firestore.collection('faculty');
  CollectionReference get _departmentsRef => _firestore.collection('departments');
  CollectionReference get _designationsRef => _firestore.collection('designations');
  CollectionReference get _locationsRef => _firestore.collection('locations');
  CollectionReference get _timetablesRef => _firestore.collection('timetables');
  CollectionReference get _exceptionsRef => _firestore.collection('timetableExceptions');
  CollectionReference get _auditLogRef => _firestore.collection('auditLog');

  /// Helper to generate a unique ID before submitting forms
  String generateId() => _firestore.collection('_').doc().id;

  /// Helper to get data with a short timeout, falling back to cache if offline
  Future<QuerySnapshot> _getWithTimeout(Query query) async {
    // Check if device is completely offline upfront
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      return await query.get(const GetOptions(source: Source.cache));
    }

    try {
      return await query.get(const GetOptions(source: Source.serverAndCache)).timeout(const Duration(seconds: 5));
    } catch (_) {
      return await query.get(const GetOptions(source: Source.cache));
    }
  }

  /// Helper to wrap write operations with a timeout
  Future<T> _writeWithTimeout<T>(Future<T> future) {
    return future.timeout(
      const Duration(seconds: 7),
      onTimeout: () => throw Exception('Network timeout. Please check your internet connection.'),
    );
  }

  /// Stream of all faculty with consent.given == true (for public directory)
  /// Field-level visibility is handled in the UI layer per SRD Sec 8.1
  Stream<List<Faculty>> getPublicFacultyStream() {
    return _facultyRef
        .where('consent.given', isEqualTo: true)
        .where('isArchived', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Faculty.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Stream of faculty for admin list (toggleable by isArchived)
  Stream<List<Faculty>> getAdminFacultyStream(bool showArchived) {
    return _facultyRef
        .where('isArchived', isEqualTo: showArchived)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Faculty.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// One-time fetch of all faculty (for caching)
  Future<List<Faculty>> fetchAllFaculty() async {
    final query = _facultyRef.where('consent.given', isEqualTo: true);
    final snapshot = await _getWithTimeout(query);
    return snapshot.docs
        .map((doc) => Faculty.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Stream of all departments
  Stream<List<Department>> getDepartmentsStream() {
    return _departmentsRef.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Department.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList());
  }

  /// One-time fetch of all departments
  Future<List<Department>> fetchAllDepartments() async {
    final snapshot = await _getWithTimeout(_departmentsRef);
    return snapshot.docs
        .map((doc) => Department.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Stream of all designations
  Stream<List<Designation>> getDesignationsStream() {
    return _designationsRef.orderBy('rank').snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Designation.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList());
  }

  /// One-time fetch of all designations
  Future<List<Designation>> fetchAllDesignations() async {
    final snapshot = await _getWithTimeout(_designationsRef.orderBy('rank'));
    return snapshot.docs
        .map((doc) => Designation.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  // ==========================================
  // LOCATIONS CRUD (Admin Phase D)
  // ==========================================

  /// Stream of all locations
  Stream<List<Location>> getLocationsStream() {
    return _locationsRef.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Location.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList());
  }

  /// One-time fetch of all locations
  Future<List<Location>> fetchAllLocations() async {
    final snapshot = await _getWithTimeout(_locationsRef);
    return snapshot.docs
        .map((doc) => Location.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Create a location (admin only)
  Future<String> createLocation(Location location) async {
    final docRef = location.id.isNotEmpty ? _locationsRef.doc(location.id) : _locationsRef.doc();
    await _writeWithTimeout(docRef.set(location.toMap()));
    
    await writeAuditLog(
      logId: 'create_loc_${docRef.id}',
      recordId: docRef.id,
      field: 'DOCUMENT_CREATED',
      oldValue: '',
      newValue: 'name: ${location.name}, building: ${location.building}, floor: ${location.floor}',
    );
    return docRef.id;
  }

  /// Update a location (admin only)
  Future<void> updateLocation(String id, Location newLoc, Location oldLoc) async {
    await _writeWithTimeout(_locationsRef.doc(id).update(newLoc.toMap()));

    if (oldLoc.name != newLoc.name) {
      await writeAuditLog(recordId: id, field: 'name', oldValue: oldLoc.name, newValue: newLoc.name);
    }
    if (oldLoc.type != newLoc.type) {
      await writeAuditLog(recordId: id, field: 'type', oldValue: oldLoc.type, newValue: newLoc.type);
    }
    if (oldLoc.building != newLoc.building) {
      await writeAuditLog(recordId: id, field: 'building', oldValue: oldLoc.building, newValue: newLoc.building);
    }
    if (oldLoc.floor != newLoc.floor) {
      await writeAuditLog(recordId: id, field: 'floor', oldValue: oldLoc.floor, newValue: newLoc.floor);
    }
    if (oldLoc.description != newLoc.description) {
      await writeAuditLog(recordId: id, field: 'description', oldValue: oldLoc.description ?? '', newValue: newLoc.description ?? '');
    }
  }

  /// Delete a location (admin only)
  Future<void> deleteLocation(String id, Location loc) async {
    final countQuery = await _facultyRef.where('locationId', isEqualTo: id).count().get();
    final count = countQuery.count ?? 0;
    
    if (count > 0) {
      throw Exception('Cannot delete — $count faculty member(s) reference this location. Reassign them first.');
    }

    await _writeWithTimeout(_locationsRef.doc(id).delete());

    await writeAuditLog(
      recordId: id,
      field: 'DOCUMENT_DELETED',
      oldValue: 'name: ${loc.name}, building: ${loc.building}, floor: ${loc.floor}',
      newValue: '',
    );
  }

  /// Get active timetable for a faculty member
  Future<(Timetable?, bool)> getActiveTimetable(String facultyId) async {
    final query = _timetablesRef
        .where('facultyId', isEqualTo: facultyId)
        .where('active', isEqualTo: true)
        .limit(1);
    final snapshot = await _getWithTimeout(query);
    final isFromCache = snapshot.metadata.isFromCache;
    if (snapshot.docs.isEmpty) return (null, isFromCache);
    final doc = snapshot.docs.first;
    return (Timetable.fromMap(doc.id, doc.data() as Map<String, dynamic>), isFromCache);
  }

  /// Get timetable exceptions for a faculty member
  Future<(List<TimetableException>, bool)> getTimetableExceptions(String facultyId) async {
    final query = _exceptionsRef
        .where('facultyId', isEqualTo: facultyId);
    final snapshot = await _getWithTimeout(query);
    final isFromCache = snapshot.metadata.isFromCache;
    final list = snapshot.docs
        .map((doc) => TimetableException.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
    return (list, isFromCache);
  }

  /// Write audit log entry (admin only)
  Future<void> writeAuditLog({
    String? logId,
    required String recordId,
    required String field,
    required String oldValue,
    required String newValue,
    WriteBatch? batch,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return; // Should not happen for admin writes

    final data = {
      'recordId': recordId,
      'field': field,
      'oldValue': oldValue,
      'newValue': newValue,
      'changedBy': user.email ?? user.uid,
      'timestamp': FieldValue.serverTimestamp(),
    };

    final docRef = logId != null ? _auditLogRef.doc(logId) : _auditLogRef.doc();

    if (batch != null) {
      batch.set(docRef, data);
    } else {
      await _writeWithTimeout(docRef.set(data));
    }
  }

  /// Create a new faculty record (admin only)
  Future<String> createFaculty(Faculty faculty) async {
    final docRef = faculty.id.isNotEmpty ? _facultyRef.doc(faculty.id) : _facultyRef.doc();
    await _writeWithTimeout(docRef.set(faculty.toMap()));
    await writeAuditLog(
      logId: 'create_fac_${docRef.id}',
      recordId: docRef.id,
      field: 'DOCUMENT_CREATED',
      oldValue: '',
      newValue: 'name: ${faculty.name}, email: ${faculty.email}',
    );
    return docRef.id;
  }

  /// Update a faculty record (admin only)
  Future<void> updateFaculty(String id, Faculty newFac, Faculty oldFac) async {
    await _writeWithTimeout(_facultyRef.doc(id).update({
      ...newFac.toMap(),
      'lastUpdated': FieldValue.serverTimestamp(),
    }));

    if (oldFac.name != newFac.name) {
      await writeAuditLog(recordId: id, field: 'name', oldValue: oldFac.name, newValue: newFac.name);
    }
    if (oldFac.departmentId != newFac.departmentId) {
      await writeAuditLog(recordId: id, field: 'departmentId', oldValue: oldFac.departmentId, newValue: newFac.departmentId);
    }
    if (oldFac.designationId != newFac.designationId) {
      await writeAuditLog(recordId: id, field: 'designationId', oldValue: oldFac.designationId, newValue: newFac.designationId);
    }
    if (oldFac.consent.given != newFac.consent.given) {
      await writeAuditLog(recordId: id, field: 'consent.given', oldValue: oldFac.consent.given.toString(), newValue: newFac.consent.given.toString());
    }
  }

  /// Delete a faculty record (admin only) - soft delete via consent and archiving
  Future<void> softDeleteFaculty(String id) async {
    await _writeWithTimeout(_facultyRef.doc(id).update({
      'isArchived': true,
      'consent.given': false,
      'lastUpdated': FieldValue.serverTimestamp(),
    }));
    await writeAuditLog(
      recordId: id,
      field: 'FACULTY_ARCHIVED',
      oldValue: 'false',
      newValue: 'true',
    );
  }

  /// Restore an archived faculty record (admin only)
  Future<void> restoreFaculty(String id) async {
    await _writeWithTimeout(_facultyRef.doc(id).update({
      'isArchived': false,
      'lastUpdated': FieldValue.serverTimestamp(),
    }));
    await writeAuditLog(
      recordId: id,
      field: 'FACULTY_RESTORED',
      oldValue: 'true',
      newValue: 'false',
    );
  }

  Future<String> uploadFacultyPhoto(File imageFile, String facultyId) async {
    final storageRef = FirebaseStorage.instance.ref().child('faculty_photos/$facultyId.jpg');
    final bytes = await imageFile.readAsBytes();
    
    // Use putData instead of putFile. putFile can sometimes fail with 404 (Upload session terminated)
    // on Android if resumable uploads encounter network/AppCheck quirks.
    final uploadTask = storageRef.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  /// Create a department (admin only)
  Future<String> createDepartment(Department department) async {
    final existing = await _departmentsRef.get();
    for (var doc in existing.docs) {
      if (department.id.isNotEmpty && doc.id == department.id) continue;
      if ((doc.data() as Map<String, dynamic>)['shortCode'].toString().toLowerCase() == department.shortCode.toLowerCase()) {
        throw Exception('A department with this short code already exists.');
      }
    }
    
    final docRef = department.id.isNotEmpty ? _departmentsRef.doc(department.id) : _departmentsRef.doc();
    await _writeWithTimeout(docRef.set(department.toMap()));
    
    await writeAuditLog(
      logId: 'create_dept_${docRef.id}',
      recordId: docRef.id,
      field: 'DOCUMENT_CREATED',
      oldValue: '',
      newValue: 'name: ${department.name}, shortCode: ${department.shortCode}',
    );
    return docRef.id;
  }

  /// Update a department (admin only)
  Future<void> updateDepartment(String id, Department newDept, Department oldDept) async {
    final existing = await _departmentsRef.get();
    for (var doc in existing.docs) {
      if (doc.id != id && (doc.data() as Map<String, dynamic>)['shortCode'].toString().toLowerCase() == newDept.shortCode.toLowerCase()) {
        throw Exception('A department with this short code already exists.');
      }
    }

    await _writeWithTimeout(_departmentsRef.doc(id).update(newDept.toMap()));

    if (oldDept.name != newDept.name) {
      await writeAuditLog(recordId: id, field: 'name', oldValue: oldDept.name, newValue: newDept.name);
    }
    if (oldDept.shortCode != newDept.shortCode) {
      await writeAuditLog(recordId: id, field: 'shortCode', oldValue: oldDept.shortCode, newValue: newDept.shortCode);
    }
  }

  /// Delete a department (admin only)
  Future<void> deleteDepartment(String id, Department dept) async {
    final countQuery = await _facultyRef.where('departmentId', isEqualTo: id).count().get();
    final count = countQuery.count ?? 0;
    
    if (count > 0) {
      throw Exception('Cannot delete — $count faculty member(s) are assigned to this department. Reassign them first.');
    }

    await _writeWithTimeout(_departmentsRef.doc(id).delete());

    await writeAuditLog(
      recordId: id,
      field: 'DOCUMENT_DELETED',
      oldValue: 'name: ${dept.name}, shortCode: ${dept.shortCode}',
      newValue: '',
    );
  }

  /// Create a designation (admin only)
  Future<String> createDesignation(Designation designation) async {
    final existing = await _designationsRef.get();
    for (var doc in existing.docs) {
      if (designation.id.isNotEmpty && doc.id == designation.id) continue;
      if ((doc.data() as Map<String, dynamic>)['title'].toString().toLowerCase() == designation.title.toLowerCase()) {
        throw Exception('A designation with this title already exists.');
      }
    }
    
    final docRef = designation.id.isNotEmpty ? _designationsRef.doc(designation.id) : _designationsRef.doc();
    await _writeWithTimeout(docRef.set(designation.toMap()));
    
    await writeAuditLog(
      logId: 'create_desig_${docRef.id}',
      recordId: docRef.id,
      field: 'DOCUMENT_CREATED',
      oldValue: '',
      newValue: 'title: ${designation.title}, rank: ${designation.rank}',
    );
    return docRef.id;
  }

  /// Update a designation (admin only)
  Future<void> updateDesignation(String id, Designation newDesig, Designation oldDesig) async {
    final existing = await _designationsRef.get();
    for (var doc in existing.docs) {
      if (doc.id != id && (doc.data() as Map<String, dynamic>)['title'].toString().toLowerCase() == newDesig.title.toLowerCase()) {
        throw Exception('A designation with this title already exists.');
      }
    }

    await _writeWithTimeout(_designationsRef.doc(id).update(newDesig.toMap()));

    if (oldDesig.title != newDesig.title) {
      await writeAuditLog(recordId: id, field: 'title', oldValue: oldDesig.title, newValue: newDesig.title);
    }
    if (oldDesig.rank != newDesig.rank) {
      await writeAuditLog(recordId: id, field: 'rank', oldValue: oldDesig.rank.toString(), newValue: newDesig.rank.toString());
    }
  }

  /// Delete a designation (admin only)
  Future<void> deleteDesignation(String id, Designation desig) async {
    final countQuery = await _facultyRef.where('designationId', isEqualTo: id).count().get();
    final count = countQuery.count ?? 0;
    
    if (count > 0) {
      throw Exception('Cannot delete — $count faculty member(s) are assigned to this designation. Reassign them first.');
    }

    await _writeWithTimeout(_designationsRef.doc(id).delete());

    await writeAuditLog(
      recordId: id,
      field: 'DOCUMENT_DELETED',
      oldValue: 'title: ${desig.title}, rank: ${desig.rank}',
      newValue: '',
    );
  }

  // ==========================================
  // TIMETABLE CRUD (Admin Phase E)
  // ==========================================

  Stream<List<Timetable>> getTimetablesStream(String facultyId) {
    return _timetablesRef
        .where('facultyId', isEqualTo: facultyId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Timetable.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  Future<String> createTimetable(Timetable timetable) async {
    final batch = _firestore.batch();
    final newDocRef = timetable.id.isNotEmpty ? _timetablesRef.doc(timetable.id) : _timetablesRef.doc();
    
    // Auto-deactivate logic if this one is active
    if (timetable.active) {
      final activeQuery = await _timetablesRef
          .where('facultyId', isEqualTo: timetable.facultyId)
          .where('active', isEqualTo: true)
          .get();
      
      for (var doc in activeQuery.docs) {
        batch.update(doc.reference, {'active': false});
        await writeAuditLog(
          recordId: doc.id,
          field: 'active',
          oldValue: 'true',
          newValue: 'false',
          batch: batch,
        );
      }
    }

    batch.set(newDocRef, timetable.toMap());
    
    await writeAuditLog(
      logId: 'create_tb_${newDocRef.id}',
      recordId: newDocRef.id,
      field: 'DOCUMENT_CREATED',
      oldValue: '',
      newValue: 'term: ${timetable.term}, active: ${timetable.active}, slots: ${timetable.slots.length}',
      batch: batch,
    );
    
    await _writeWithTimeout(batch.commit());
    return newDocRef.id;
  }

  Future<void> updateTimetable(String id, Timetable newTb, Timetable oldTb) async {
    final batch = _firestore.batch();
    
    // Auto-deactivate logic if this one is active
    if (newTb.active && !oldTb.active) {
      final activeQuery = await _timetablesRef
          .where('facultyId', isEqualTo: newTb.facultyId)
          .where('active', isEqualTo: true)
          .get();
      
      for (var doc in activeQuery.docs) {
        if (doc.id != id) {
          batch.update(doc.reference, {'active': false});
          await writeAuditLog(
            recordId: doc.id,
            field: 'active',
            oldValue: 'true',
            newValue: 'false',
            batch: batch,
          );
        }
      }
    }

    batch.update(_timetablesRef.doc(id), newTb.toMap());

    if (oldTb.term != newTb.term) {
      await writeAuditLog(recordId: id, field: 'term', oldValue: oldTb.term, newValue: newTb.term, batch: batch);
    }
    if (oldTb.active != newTb.active) {
      await writeAuditLog(recordId: id, field: 'active', oldValue: oldTb.active.toString(), newValue: newTb.active.toString(), batch: batch);
    }
    if (oldTb.slots.length != newTb.slots.length) {
      await writeAuditLog(recordId: id, field: 'slots', oldValue: '${oldTb.slots.length} slots', newValue: '${newTb.slots.length} slots', batch: batch);
    }

    await _writeWithTimeout(batch.commit());
  }

  Future<void> deleteTimetable(String id, Timetable tb) async {
    final batch = _firestore.batch();
    batch.delete(_timetablesRef.doc(id));
    
    await writeAuditLog(
      recordId: id,
      field: 'DOCUMENT_DELETED',
      oldValue: 'term: ${tb.term}, active: ${tb.active}',
      newValue: '',
      batch: batch,
    );
    
    await _writeWithTimeout(batch.commit());
  }

  // ==========================================
  // TIMETABLE EXCEPTIONS CRUD (Admin Phase E)
  // ==========================================

  Stream<List<TimetableException>> getTimetableExceptionsStream(String facultyId) {
    return _exceptionsRef
        .where('facultyId', isEqualTo: facultyId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => TimetableException.fromMap(doc.id, doc.data() as Map<String, dynamic>))
              .toList();
          list.sort((a, b) => b.date.compareTo(a.date)); // Sort locally to avoid composite index
          return list;
        });
  }

  Future<String> createTimetableException(TimetableException ex) async {
    final batch = _firestore.batch();
    final newDocRef = ex.id.isNotEmpty ? _exceptionsRef.doc(ex.id) : _exceptionsRef.doc();
    
    batch.set(newDocRef, ex.toMap());
    
    await writeAuditLog(
      logId: 'create_ex_${newDocRef.id}',
      recordId: newDocRef.id,
      field: 'DOCUMENT_CREATED',
      oldValue: '',
      newValue: 'date: ${ex.date.toIso8601String()}, type: ${ex.type}',
      batch: batch,
    );
    
    await _writeWithTimeout(batch.commit());
    return newDocRef.id;
  }

  Future<void> updateTimetableException(String id, TimetableException newEx, TimetableException oldEx) async {
    final batch = _firestore.batch();
    batch.update(_exceptionsRef.doc(id), newEx.toMap());

    if (oldEx.date != newEx.date) {
      await writeAuditLog(recordId: id, field: 'date', oldValue: oldEx.date.toIso8601String(), newValue: newEx.date.toIso8601String(), batch: batch);
    }
    if (oldEx.type != newEx.type) {
      await writeAuditLog(recordId: id, field: 'type', oldValue: oldEx.type, newValue: newEx.type, batch: batch);
    }
    if (oldEx.note != newEx.note) {
      await writeAuditLog(recordId: id, field: 'note', oldValue: oldEx.note ?? '', newValue: newEx.note ?? '', batch: batch);
    }

    await _writeWithTimeout(batch.commit());
  }

  Future<void> deleteTimetableException(String id, TimetableException ex) async {
    final batch = _firestore.batch();
    batch.delete(_exceptionsRef.doc(id));
    
    await writeAuditLog(
      recordId: id,
      field: 'DOCUMENT_DELETED',
      oldValue: 'date: ${ex.date.toIso8601String()}, type: ${ex.type}',
      newValue: '',
      batch: batch,
    );
    
    await _writeWithTimeout(batch.commit());
  }
}