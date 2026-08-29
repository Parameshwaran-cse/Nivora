class TimetableSlot {
  final String dayOfWeek; // 'monday', 'tuesday', etc.
  final String startTime; // "09:00"
  final String endTime;   // "10:00"
  final String type; // "class" / "office-hours"
  final String? subject;
  final String? room;

  TimetableSlot({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.type,
    this.subject,
    this.room,
  });

  factory TimetableSlot.fromMap(Map<String, dynamic> map) {
    return TimetableSlot(
      dayOfWeek: map['dayOfWeek'] ?? 'monday',
      startTime: map['startTime'] ?? '00:00',
      endTime: map['endTime'] ?? '00:00',
      type: map['type'] ?? 'class',
      subject: map['subject'],
      room: map['room'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'type': type,
      'subject': subject,
      'room': room,
    };
  }
}

class Timetable {
  final String id;
  final String facultyId;
  final String term; // e.g., "2026-Odd"
  final bool active;
  final String day; // Mon–Sat
  final List<TimetableSlot> slots;

  Timetable({
    required this.id,
    required this.facultyId,
    required this.term,
    required this.active,
    required this.day,
    required this.slots,
  });

  factory Timetable.fromMap(String id, Map<String, dynamic> map) {
    return Timetable(
      id: id,
      facultyId: map['facultyId'] ?? '',
      term: map['term'] ?? '',
      active: map['active'] ?? false,
      day: map['day'] ?? '',
      slots: (map['slots'] as List<dynamic>? ?? [])
          .map((s) => TimetableSlot.fromMap(s as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'facultyId': facultyId,
      'term': term,
      'active': active,
      'day': day,
      'slots': slots.map((s) => s.toMap()).toList(),
    };
  }
}