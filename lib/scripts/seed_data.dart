import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

Future<void> runSeed() async {
  final firestore = FirebaseFirestore.instance;
  
  // 1. Wipe existing timetables and exceptions
  final ttSnap = await firestore.collection('timetables').get();
  for (var doc in ttSnap.docs) {
    await doc.reference.delete();
  }
  
  final exSnap = await firestore.collection('timetableExceptions').get();
  for (var doc in exSnap.docs) {
    await doc.reference.delete();
  }

  // 2. Fetch faculty
  final facultySnap = await firestore.collection('faculty').get();
  final facultyList = facultySnap.docs.map((doc) => Faculty.fromMap(doc.id, doc.data())).toList();

  if (facultyList.length < 5) {
    print('Not enough faculty to seed test cases. Need at least 5.');
    return;
  }

  final now = DateTime.now();
  final weekdayStr = _getWeekdayString(now.weekday);
  
  // Generate time strings covering now
  final startHour = now.hour;
  final endHour = (now.hour + 1) % 24;
  final startStr = '${startHour.toString().padLeft(2, '0')}:00';
  final endStr = '${endHour.toString().padLeft(2, '0')}:00';
  
  // Generate a slot that is explicitly NOT covering now
  final offStartStr = '${(now.hour + 2) % 24}'.padLeft(2, '0') + ':00';
  final offEndStr = '${(now.hour + 3) % 24}'.padLeft(2, '0') + ':00';

  // Helper to save timetable
  Future<void> addTimetable(Faculty f, List<TimetableSlot> slots) async {
    final t = Timetable(
      id: '',
      facultyId: f.id,
      term: '2026-Odd',
      active: true,
      day: 'N/A', // legacy field, kept for safety
      slots: slots,
    );
    await firestore.collection('timetables').add(t.toMap());
  }

  // 1. "In Class" (Faculty 0)
  final f0 = facultyList[0];
  await firestore.collection('faculty').doc(f0.id).update({'consent.allowLiveStatus': true});
  await addTimetable(f0, [
    TimetableSlot(
      dayOfWeek: weekdayStr,
      startTime: startStr,
      endTime: endStr,
      type: 'class',
      subject: 'CS101',
      room: 'Room A1',
    )
  ]);

  // 2. "Available" (Faculty 1)
  final f1 = facultyList[1];
  await firestore.collection('faculty').doc(f1.id).update({'consent.allowLiveStatus': true});
  await addTimetable(f1, [
    TimetableSlot(
      dayOfWeek: weekdayStr,
      startTime: startStr,
      endTime: endStr,
      type: 'office-hours',
      room: 'Cabin B2',
    )
  ]);

  // 3. "On Leave" Exception (Faculty 2)
  final f2 = facultyList[2];
  await firestore.collection('faculty').doc(f2.id).update({'consent.allowLiveStatus': true});
  // Can also give them a class slot, but exception should override
  await addTimetable(f2, [
    TimetableSlot(dayOfWeek: weekdayStr, startTime: startStr, endTime: endStr, type: 'class', room: 'Room C3')
  ]);
  final ex = TimetableException(
    id: '',
    facultyId: f2.id,
    date: DateTime(now.year, now.month, now.day),
    type: 'leave',
    note: 'Sick leave',
  );
  await firestore.collection('timetableExceptions').add(ex.toMap());

  // 4. "Unknown" (Faculty 3)
  final f3 = facultyList[3];
  await firestore.collection('faculty').doc(f3.id).update({'consent.allowLiveStatus': true});
  await addTimetable(f3, [
    TimetableSlot(
      dayOfWeek: weekdayStr,
      startTime: offStartStr,
      endTime: offEndStr,
      type: 'class',
      room: 'Room D4',
    )
  ]);

  // 5. No live status consent (Faculty 4)
  final f4 = facultyList[4];
  await firestore.collection('faculty').doc(f4.id).update({'consent.allowLiveStatus': false});
  // Give them a slot right now, but UI should hide it
  await addTimetable(f4, [
    TimetableSlot(
      dayOfWeek: weekdayStr,
      startTime: startStr,
      endTime: endStr,
      type: 'class',
      room: 'Room E5',
    )
  ]);

  print('=== SEED COMPLETE ===');
  print('1. In Class: ${f0.name}');
  print('2. Available: ${f1.name}');
  print('3. On Leave: ${f2.name}');
  print('4. Unknown: ${f3.name}');
  print('5. Hidden: ${f4.name}');
}

String _getWeekdayString(int weekday) {
  switch (weekday) {
    case 1: return 'monday';
    case 2: return 'tuesday';
    case 3: return 'wednesday';
    case 4: return 'thursday';
    case 5: return 'friday';
    case 6: return 'saturday';
    case 7: return 'sunday';
    default: return 'monday';
  }
}
