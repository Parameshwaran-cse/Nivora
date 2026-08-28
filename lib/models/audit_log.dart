import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLog {
  final String id;
  final String recordId;
  final String field;
  final String oldValue;
  final String newValue;
  final String changedBy;
  final DateTime timestamp;

  AuditLog({
    required this.id,
    required this.recordId,
    required this.field,
    required this.oldValue,
    required this.newValue,
    required this.changedBy,
    required this.timestamp,
  });

  factory AuditLog.fromMap(String id, Map<String, dynamic> map) {
    return AuditLog(
      id: id,
      recordId: map['recordId'] ?? '',
      field: map['field'] ?? '',
      oldValue: map['oldValue'] ?? '',
      newValue: map['newValue'] ?? '',
      changedBy: map['changedBy'] ?? '',
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recordId': recordId,
      'field': field,
      'oldValue': oldValue,
      'newValue': newValue,
      'changedBy': changedBy,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}