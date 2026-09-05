import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../utils/theme.dart';

class AdminTimetableFormScreen extends StatefulWidget {
  final Faculty faculty;
  final Timetable? existingTimetable;

  const AdminTimetableFormScreen({
    super.key,
    required this.faculty,
    this.existingTimetable,
  });

  @override
  State<AdminTimetableFormScreen> createState() => _AdminTimetableFormScreenState();
}

class _AdminTimetableFormScreenState extends State<AdminTimetableFormScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirestoreService();
  bool _isProcessing = false;
  late TabController _tabController;
  String? _newDocId;

  late TextEditingController _termController;
  bool _isActive = false;

  final List<String> _days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
  final Map<String, List<TimetableSlot>> _slotsByDay = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    
    _termController = TextEditingController(text: widget.existingTimetable?.term ?? '');
    _isActive = widget.existingTimetable?.active ?? false;

    for (var day in _days) {
      _slotsByDay[day] = [];
    }

    if (widget.existingTimetable != null) {
      for (var slot in widget.existingTimetable!.slots) {
        final d = slot.dayOfWeek.toLowerCase();
        if (_slotsByDay.containsKey(d)) {
          _slotsByDay[d]!.add(slot);
        }
      }
    }
  }

  @override
  void dispose() {
    _termController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  void _showWarning(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.orange),
    );
  }

  int _timeToMinutes(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length != 2) return 0;
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  bool _hasOverlap(String day, String startTime, String endTime, [TimetableSlot? skipSlot]) {
    final startMin = _timeToMinutes(startTime);
    final endMin = _timeToMinutes(endTime);

    for (var s in _slotsByDay[day]!) {
      if (s == skipSlot) continue;
      final sStart = _timeToMinutes(s.startTime);
      final sEnd = _timeToMinutes(s.endTime);

      if (startMin < sEnd && endMin > sStart) {
        return true;
      }
    }
    return false;
  }

  Future<void> _showSlotDialog(String day, {TimetableSlot? existingSlot, int? editIndex}) async {
    final startTimeCtrl = TextEditingController(text: existingSlot?.startTime ?? '09:00');
    final endTimeCtrl = TextEditingController(text: existingSlot?.endTime ?? '10:00');
    final subjectCtrl = TextEditingController(text: existingSlot?.subject ?? '');
    final roomCtrl = TextEditingController(text: existingSlot?.room ?? '');
    String type = existingSlot?.type ?? 'class';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.darkCardBg,
              title: Text(existingSlot == null ? 'Add Slot - ${day.toUpperCase()}' : 'Edit Slot'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final parts = startTimeCtrl.text.split(':');
                              final current = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
                              final picked = await showTimePicker(context: context, initialTime: current);
                              if (picked != null) {
                                setDialogState(() {
                                  startTimeCtrl.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Start Time *'),
                              child: Text(startTimeCtrl.text, style: const TextStyle(color: Colors.white)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final parts = endTimeCtrl.text.split(':');
                              final current = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
                              final picked = await showTimePicker(context: context, initialTime: current);
                              if (picked != null) {
                                setDialogState(() {
                                  endTimeCtrl.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'End Time *'),
                              child: Text(endTimeCtrl.text, style: const TextStyle(color: Colors.white)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Type *'),
                      dropdownColor: AppTheme.darkCardBg,
                      initialValue: type,
                      items: const [
                        DropdownMenuItem(value: 'class', child: Text('Class')),
                        DropdownMenuItem(value: 'office-hours', child: Text('Office Hours')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => type = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: subjectCtrl,
                      decoration: const InputDecoration(labelText: 'Subject (Optional)'),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: roomCtrl,
                      decoration: const InputDecoration(labelText: 'Room (Optional)'),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                ),
                TextButton(
                  onPressed: () {
                    final startMin = _timeToMinutes(startTimeCtrl.text);
                    final endMin = _timeToMinutes(endTimeCtrl.text);
                    if (startMin >= endMin) {
                      _showError('End time must be after start time.');
                      return;
                    }

                    if (_hasOverlap(day, startTimeCtrl.text, endTimeCtrl.text, existingSlot)) {
                      _showWarning('Warning: This slot overlaps with an existing slot on $day.');
                    }

                    final newSlot = TimetableSlot(
                      dayOfWeek: day,
                      startTime: startTimeCtrl.text,
                      endTime: endTimeCtrl.text,
                      type: type,
                      subject: subjectCtrl.text.trim().isEmpty ? null : subjectCtrl.text.trim(),
                      room: roomCtrl.text.trim().isEmpty ? null : roomCtrl.text.trim(),
                    );

                    setState(() {
                      if (existingSlot != null && editIndex != null) {
                        _slotsByDay[day]![editIndex] = newSlot;
                      } else {
                        _slotsByDay[day]!.add(newSlot);
                      }
                      // Sort by start time
                      _slotsByDay[day]!.sort((a, b) => _timeToMinutes(a.startTime).compareTo(_timeToMinutes(b.startTime)));
                    });

                    Navigator.pop(context);
                  },
                  child: const Text('Save', style: TextStyle(color: AppTheme.darkAccent)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    final term = _termController.text.trim();
    if (term.isEmpty) {
      _showError('Term is required.');
      return;
    }

    final allSlots = _slotsByDay.values.expand((element) => element).toList();
    if (allSlots.isEmpty && _isActive) {
      _showError('At least one slot must be defined to save an active timetable.');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      _newDocId ??= _firestore.generateId();

      final newTb = Timetable(
        id: widget.existingTimetable?.id ?? _newDocId!,
        facultyId: widget.faculty.id,
        term: term,
        active: _isActive,
        day: '', // no longer used natively, but required by model constructor
        slots: allSlots,
      );

      if (widget.existingTimetable != null) {
        await _firestore.updateTimetable(widget.existingTimetable!.id, newTb, widget.existingTimetable!);
      } else {
        await _firestore.createTimetable(newTb);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingTimetable == null ? 'New Timetable' : 'Edit Timetable'),
        actions: [
          if (_isProcessing)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check_rounded, color: AppTheme.darkAccent),
              onPressed: _save,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.darkAccent,
          labelColor: AppTheme.darkAccent,
          unselectedLabelColor: Colors.white54,
          isScrollable: true,
          tabs: _days.map((day) => Tab(text: day.substring(0, 3).toUpperCase())).toList(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _termController,
                      decoration: const InputDecoration(
                        labelText: 'Term (e.g. 2026-Odd) *',
                        prefixIcon: Icon(Icons.class_outlined, color: Colors.white54),
                      ),
                      style: const TextStyle(color: Colors.white),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    children: [
                      const Text('Active', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      Switch(
                        value: _isActive,
                        onChanged: (val) => setState(() => _isActive = val),
                        activeThumbColor: AppTheme.darkAccent,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _days.map((day) {
                  final slots = _slotsByDay[day]!;
                  return Column(
                    children: [
                      Expanded(
                        child: slots.isEmpty
                            ? const Center(child: Text('No slots defined for this day.', style: TextStyle(color: Colors.white54)))
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: slots.length,
                                itemBuilder: (context, index) {
                                  final slot = slots[index];
                                  return Card(
                                    color: AppTheme.darkCardBg,
                                    margin: const EdgeInsets.only(bottom: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: ListTile(
                                      title: Text('${slot.startTime} - ${slot.endTime}'),
                                      subtitle: Text(
                                        '${slot.type.toUpperCase()}${slot.subject != null ? ' • ${slot.subject}' : ''}${slot.room != null ? ' • ${slot.room}' : ''}',
                                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit_rounded, color: AppTheme.darkAccent, size: 20),
                                            onPressed: () => _showSlotDialog(day, existingSlot: slot, editIndex: index),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                            onPressed: () {
                                              setState(() {
                                                _slotsByDay[day]!.removeAt(index);
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton.icon(
                          onPressed: () => _showSlotDialog(day),
                          icon: const Icon(Icons.add_rounded),
                          label: Text('Add Slot for ${day.toUpperCase()}'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white10,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
