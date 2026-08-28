import 'package:cloud_firestore/cloud_firestore.dart';

class TimetableException {
  final String id;
  final String facultyId;
  final DateTime date;
  final String type; // "holiday" / "leave" / "substitution"
  final String? note;

  TimetableException({
    required this.id,
    required this.facultyId,
    required this.date,
    required this.type,
    this.note,
  });

  factory TimetableException.fromMap(String id, Map<String, dynamic> map) {
    return TimetableException(
      id: id,
      facultyId: map['facultyId'] ?? '',
      date: map['date'] != null
          ? (map['date'] as Timestamp).toDate()
          : DateTime.now(),
      type: map['type'] ?? '',
      note: map['note'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'facultyId': facultyId,
      'date': Timestamp.fromDate(date),
      'type': type,
      'note': note,
    };
  }
}