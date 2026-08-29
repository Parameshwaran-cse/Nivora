import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/faculty.dart';
import '../../models/timetable.dart';
import '../../models/timetable_exception.dart';
import '../../providers/timetable_provider.dart';
import '../../utils/theme.dart';

class FacultyTimetableScreen extends StatefulWidget {
  final Faculty faculty;

  const FacultyTimetableScreen({super.key, required this.faculty});

  @override
  State<FacultyTimetableScreen> createState() => _FacultyTimetableScreenState();
}

class _FacultyTimetableScreenState extends State<FacultyTimetableScreen> {
  // Start with today's weekday index (1=Mon, 7=Sun). If Sunday, default to Mon.
  int _selectedDayIndex = DateTime.now().weekday;

  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  final List<String> _dayKeys = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];

  @override
  void initState() {
    super.initState();
    if (_selectedDayIndex > 6) _selectedDayIndex = 1; // Default Sun to Mon
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("${widget.faculty.name}'s Timetable"),
      ),
      body: Consumer<TimetableProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final timetable = provider.getTimetable(widget.faculty.id);
          final exceptions = provider.getExceptions(widget.faculty.id);

          return Column(
            children: [
              _buildDayPicker(),
              if (provider.isUsingCachedData)
                _buildOfflineIndicator(),
              _buildExceptionBanner(exceptions),
              Expanded(
                child: _buildSlotList(timetable),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDayPicker() {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _days.length,
        itemBuilder: (context, index) {
          final isSelected = (index + 1) == _selectedDayIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ChoiceChip(
              label: Text(
                _days[index],
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppTheme.darkEmphasizedText : AppTheme.darkTextPrimary,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedDayIndex = index + 1;
                  });
                }
              },
              backgroundColor: AppTheme.darkCardBg,
              selectedColor: AppTheme.darkAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildOfflineIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.darkCardBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 16, color: AppTheme.darkTextSecondary),
          const SizedBox(width: 8),
          Text(
            'Viewing offline cached timetable',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.darkTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExceptionBanner(List<TimetableException> exceptions) {
    // To accurately check exceptions for the *selected day*, we need a DateTime
    // Let's figure out what date the selected day refers to (e.g., in the current week)
    final now = DateTime.now();
    final difference = _selectedDayIndex - now.weekday;
    final selectedDate = DateTime(now.year, now.month, now.day).add(Duration(days: difference));

    final selectedExceptions = exceptions.where((e) {
      return e.date.year == selectedDate.year &&
             e.date.month == selectedDate.month &&
             e.date.day == selectedDate.day;
    }).toList();

    if (selectedExceptions.isEmpty) return const SizedBox.shrink();

    final exception = selectedExceptions.first;
    final typeLabel = exception.type == 'leave' ? 'On Leave' : (exception.type == 'holiday' ? 'Holiday' : 'Unavailable');
    final detailText = exception.note ?? 'No details provided';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.statusInClassBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.statusWarning.withAlpha(50)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppTheme.statusWarning),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  typeLabel,
                  style: const TextStyle(
                    color: AppTheme.statusWarning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detailText,
                  style: TextStyle(
                    color: AppTheme.statusWarning.withAlpha(200),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotList(Timetable? timetable) {
    if (timetable == null) {
      return const Center(
        child: Text(
          'No timetable found.',
          style: TextStyle(color: AppTheme.darkTextSecondary),
        ),
      );
    }

    final selectedKey = _dayKeys[_selectedDayIndex - 1];
    final daySlots = timetable.slots.where((s) => s.dayOfWeek.toLowerCase() == selectedKey).toList();

    // Sort by start time
    daySlots.sort((a, b) => a.startTime.compareTo(b.startTime));

    if (daySlots.isEmpty) {
      return const Center(
        child: Text(
          'No scheduled classes for this day.',
          style: TextStyle(color: AppTheme.darkTextSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: daySlots.length,
      itemBuilder: (context, index) {
        final slot = daySlots[index];
        final isClass = slot.type == 'class';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      slot.startTime,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      slot.endTime,
                      style: const TextStyle(
                        color: AppTheme.darkTextSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isClass ? AppTheme.darkAccent : AppTheme.statusAvailableText,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isClass ? (slot.subject ?? 'Class') : 'Office Hours',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (slot.room != null && slot.room!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.darkTextSecondary),
                            const SizedBox(width: 4),
                            Text(
                              slot.room!,
                              style: const TextStyle(
                                color: AppTheme.darkTextSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ]
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
