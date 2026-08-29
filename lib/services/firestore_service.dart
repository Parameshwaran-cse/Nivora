import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  /// Stream of all faculty with consent.given == true
  /// Field-level visibility is handled in the UI layer per SRD Sec 8.1
  Stream<List<Faculty>> getPublicFacultyStream() {
    return _facultyRef
        .where('consent.given', isEqualTo: true)
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
      'changedBy': user.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Create a new faculty record (admin only)
  Future<String> createFaculty(Faculty faculty) async {
    final docRef = await _facultyRef.add(faculty.toMap());
    return docRef.id;
  }

  /// Update a faculty record (admin only)
  Future<void> updateFaculty(String id, Map<String, dynamic> data) async {
    await _facultyRef.doc(id).update({
      ...data,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a faculty record (admin only) - soft delete via consent
  Future<void> softDeleteFaculty(String id) async {
    await _facultyRef.doc(id).update({
      'consent.given': false,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }
}