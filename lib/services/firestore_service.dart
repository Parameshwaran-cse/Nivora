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
    required String recordId,
    required String field,
    required String oldValue,
    required String newValue,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return; // Should not happen for admin writes

    await _auditLogRef.add({
      'recordId': recordId,
      'field': field,
      'oldValue': oldValue,
      'newValue': newValue,
      'changedBy': user.email ?? user.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Create a new faculty record (admin only)
  Future<String> createFaculty(Faculty faculty) async {
    final docRef = await _facultyRef.add(faculty.toMap());
    await writeAuditLog(
      recordId: docRef.id,
      field: 'DOCUMENT_CREATED',
      oldValue: '',
      newValue: 'name: ${faculty.name}, email: ${faculty.email}',
    );
    return docRef.id;
  }

  /// Update a faculty record (admin only)
  Future<void> updateFaculty(String id, Faculty newFac, Faculty oldFac) async {
    await _facultyRef.doc(id).update({
      ...newFac.toMap(),
      'lastUpdated': FieldValue.serverTimestamp(),
    });

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
    await _facultyRef.doc(id).update({
      'isArchived': true,
      'consent.given': false,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
    await writeAuditLog(
      recordId: id,
      field: 'FACULTY_ARCHIVED',
      oldValue: 'false',
      newValue: 'true',
    );
  }

  /// Restore an archived faculty record (admin only)
  Future<void> restoreFaculty(String id) async {
    await _facultyRef.doc(id).update({
      'isArchived': false,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
    await writeAuditLog(
      recordId: id,
      field: 'FACULTY_RESTORED',
      oldValue: 'true',
      newValue: 'false',
    );
  }

  /// Upload a faculty photo and return the download URL
  Future<String> uploadFacultyPhoto(File imageFile, String facultyId) async {
    final storageRef = FirebaseStorage.instance.ref().child('faculty_photos/$facultyId.jpg');
    final uploadTask = storageRef.putFile(imageFile);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  /// Create a department (admin only)
  Future<String> createDepartment(Department department) async {
    final existing = await _departmentsRef.get();
    for (var doc in existing.docs) {
      if ((doc.data() as Map<String, dynamic>)['shortCode'].toString().toLowerCase() == department.shortCode.toLowerCase()) {
        throw Exception('A department with this short code already exists.');
      }
    }
    
    final docRef = await _departmentsRef.add(department.toMap());
    
    await writeAuditLog(
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

    await _departmentsRef.doc(id).update(newDept.toMap());

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

    await _departmentsRef.doc(id).delete();

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
      if ((doc.data() as Map<String, dynamic>)['title'].toString().toLowerCase() == designation.title.toLowerCase()) {
        throw Exception('A designation with this title already exists.');
      }
    }
    
    final docRef = await _designationsRef.add(designation.toMap());
    
    await writeAuditLog(
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

    await _designationsRef.doc(id).update(newDesig.toMap());

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

    await _designationsRef.doc(id).delete();

    await writeAuditLog(
      recordId: id,
      field: 'DOCUMENT_DELETED',
      oldValue: 'title: ${desig.title}, rank: ${desig.rank}',
      newValue: '',
    );
  }
}