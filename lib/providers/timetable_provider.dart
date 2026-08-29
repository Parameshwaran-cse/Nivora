import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

class TimetableProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();

  // Cache by facultyId
  final Map<String, Timetable> _timetables = {};
  final Map<String, List<TimetableException>> _exceptions = {};

  bool _isLoading = false;
  String? _error;
  bool _isUsingCachedData = false;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isUsingCachedData => _isUsingCachedData;

  Timetable? getTimetable(String facultyId) => _timetables[facultyId];
  List<TimetableException> getExceptions(String facultyId) => _exceptions[facultyId] ?? [];

  Future<void> fetchTimetableData(String facultyId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _firestore.getActiveTimetable(facultyId),
        _firestore.getTimetableExceptions(facultyId),
      ]);

      final timetableResult = results[0] as (Timetable?, bool);
      final exceptionsResult = results[1] as (List<TimetableException>, bool);

      if (timetableResult.$1 != null) {
        _timetables[facultyId] = timetableResult.$1!;
      }
      _exceptions[facultyId] = exceptionsResult.$1;
      _isUsingCachedData = timetableResult.$2 || exceptionsResult.$2;
    } catch (e) {
      _error = 'Failed to load timetable: $e';
      _isUsingCachedData = _timetables.containsKey(facultyId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Evaluates real-time status strictly
  String getCurrentStatus(Faculty faculty) {
    // Note: consumer should check consent.allowLiveStatus before showing this.
    final exceptions = getExceptions(faculty.id);
    final timetable = getTimetable(faculty.id);
    final now = DateTime.now();
    
    // 1. Exceptions override everything
    final todayExceptions = exceptions.where((e) {
      return now.year == e.date.year &&
             now.month == e.date.month &&
             now.day == e.date.day;
    }).toList();

    if (todayExceptions.isNotEmpty) {
      final type = todayExceptions.first.type;
      if (type == 'leave') return 'On Leave';
      if (type == 'holiday') return 'Holiday';
      return 'Unavailable';
    }

    // 2. Active slots
    if (timetable != null) {
      // Find today's slots
      final weekdayStr = _getWeekdayString(now.weekday);
      final todaySlots = timetable.slots.where((s) => s.dayOfWeek.toLowerCase() == weekdayStr).toList();
      
      for (final slot in todaySlots) {
        // Parse "HH:MM"
        final startParts = slot.startTime.split(':');
        final endParts = slot.endTime.split(':');
        
        if (startParts.length == 2 && endParts.length == 2) {
          final start = DateTime(now.year, now.month, now.day, int.parse(startParts[0]), int.parse(startParts[1]));
          final end = DateTime(now.year, now.month, now.day, int.parse(endParts[0]), int.parse(endParts[1]));
          
          if ((now.isAfter(start) || now.isAtSameMomentAs(start)) && now.isBefore(end)) {
            if (slot.type == 'class') return 'In Class';
            if (slot.type == 'office-hours') return 'Available';
          }
        }
      }
    }

    // 3. Strict fallback
    return 'Unknown';
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
}
