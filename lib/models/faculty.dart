import 'package:cloud_firestore/cloud_firestore.dart';
import 'consent.dart';
import 'visibility.dart';

class Faculty {
  final String id;
  final String name;
  final String departmentId;
  final String designationId;
  final String cabinNo;
  final String? locationId;
  final String? phone;
  final String? email;
  final String? photoUrl;
  final String? timetableId;
  final Consent consent;
  final Visibility visibility;
  final DateTime lastUpdated;

  Faculty({
    required this.id,
    required this.name,
    required this.departmentId,
    required this.designationId,
    required this.cabinNo,
    this.locationId,
    this.phone,
    this.email,
    this.photoUrl,
    this.timetableId,
    required this.consent,
    required this.visibility,
    required this.lastUpdated,
  });

  factory Faculty.fromMap(String id, Map<String, dynamic> map) {
    return Faculty(
      id: id,
      name: map['name'] ?? '',
      departmentId: map['departmentId'] ?? '',
      designationId: map['designationId'] ?? '',
      cabinNo: map['cabinNo'] ?? '',
      locationId: map['locationId'],
      phone: map['phone'],
      email: map['email'],
      photoUrl: map['photoUrl'],
      timetableId: map['timetableId'],
      consent: Consent.fromMap(map['consent'] ?? {}),
      visibility: Visibility.fromMap(map['visibility'] ?? {}),
      lastUpdated: map['lastUpdated'] != null
          ? (map['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'departmentId': departmentId,
      'designationId': designationId,
      'cabinNo': cabinNo,
      'locationId': locationId,
      'phone': phone,
      'email': email,
      'photoUrl': photoUrl,
      'timetableId': timetableId,
      'consent': consent.toMap(),
      'visibility': visibility.toMap(),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  /// Returns true if this faculty record should be visible in public queries
  bool get isPubliclyVisible => consent.given;

  /// Returns display name with department/designation for disambiguation (FR-1.5)
  String getDisplayName({String? departmentName, String? designationTitle}) {
    if (departmentName != null && designationTitle != null) {
      return '$name • $departmentName • $designationTitle';
    }
    return name;
  }

  // --- Visibility Helpers (SRD Sec 6) ---
  bool get canShowName => consent.given && visibility.name;
  bool get canShowPhoto => consent.given && visibility.photo;
  bool get canShowDepartment => consent.given && visibility.department;
  bool get canShowCabinNo => consent.given && visibility.cabinNo;
  bool get canShowPhone => consent.given && visibility.phone;
  bool get canShowEmail => consent.given && visibility.email;
}