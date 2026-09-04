import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../utils/theme.dart';

class AdminExceptionFormScreen extends StatefulWidget {
  final Faculty faculty;
  final TimetableException? existingException;

  const AdminExceptionFormScreen({
    super.key,
    required this.faculty,
    this.existingException,
  });

  @override
  State<AdminExceptionFormScreen> createState() => _AdminExceptionFormScreenState();
}

class _AdminExceptionFormScreenState extends State<AdminExceptionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirestoreService();
  bool _isProcessing = false;

  DateTime? _selectedDate;
  String _type = 'leave';
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.existingException?.date;
    _type = widget.existingException?.type ?? 'leave';
    _noteController = TextEditingController(text: widget.existingException?.note ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _selectDate() async {
    final initialDate = _selectedDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.darkAccent,
              onPrimary: AppTheme.darkColor,
              surface: AppTheme.darkCardBg,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      _showError('Please select a date.');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final newEx = TimetableException(
        id: widget.existingException?.id ?? '',
        facultyId: widget.faculty.id,
        date: _selectedDate!,
        type: _type,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );

      if (widget.existingException != null) {
        await _firestore.updateTimetableException(widget.existingException!.id, newEx, widget.existingException!);
      } else {
        await _firestore.createTimetableException(newEx);
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
        title: Text(widget.existingException == null ? 'New Exception' : 'Edit Exception'),
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
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date *',
                  prefixIcon: Icon(Icons.calendar_today_rounded, color: Colors.white54),
                ),
                child: Text(
                  _selectedDate == null
                      ? 'Select Date'
                      : '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: _selectedDate == null ? Colors.white54 : Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Type *',
                prefixIcon: Icon(Icons.category_rounded, color: Colors.white54),
              ),
              dropdownColor: AppTheme.darkCardBg,
              initialValue: _type,
              items: const [
                DropdownMenuItem(value: 'leave', child: Text('On Leave')),
                DropdownMenuItem(value: 'holiday', child: Text('Holiday')),
                DropdownMenuItem(value: 'substitution', child: Text('Substitution')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _type = val);
                }
              },
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (Optional)',
                prefixIcon: Icon(Icons.notes_rounded, color: Colors.white54),
              ),
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}
