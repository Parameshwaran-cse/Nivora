import 'package:cloud_firestore/cloud_firestore.dart';

class Consent {
  final bool given;
  final DateTime? dateGiven;
  final String? collectedBy;
  final String? method;
  final bool allowLiveStatus;

  Consent({
    required this.given,
    this.dateGiven,
    this.collectedBy,
    this.method,
    this.allowLiveStatus = false,
  });

  factory Consent.fromMap(Map<String, dynamic> map) {
    return Consent(
      given: map['given'] ?? false,
      dateGiven: map['dateGiven'] != null
          ? (map['dateGiven'] as Timestamp).toDate()
          : null,
      collectedBy: map['collectedBy'],
      method: map['method'],
      allowLiveStatus: map['allowLiveStatus'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'given': given,
      'dateGiven': dateGiven != null ? Timestamp.fromDate(dateGiven!) : null,
      'collectedBy': collectedBy,
      'method': method,
      'allowLiveStatus': allowLiveStatus,
    };
  }
}