import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../utils/theme.dart';
import 'admin_timetable_form_screen.dart';
import 'admin_exception_form_screen.dart';

class AdminFacultyTimetableScreen extends StatefulWidget {
  final Faculty faculty;
  const AdminFacultyTimetableScreen({super.key, required this.faculty});

  @override
  State<AdminFacultyTimetableScreen> createState() => _AdminFacultyTimetableScreenState();
}

class _AdminFacultyTimetableScreenState extends State<AdminFacultyTimetableScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _firestore = FirestoreService();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _confirmDeleteTimetable(Timetable tb) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCardBg,
        title: const Text('Delete Timetable'),
        content: Text('Are you sure you want to delete the timetable for ${tb.term}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: _isProcessing ? null : () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);
    try {
      await _firestore.deleteTimetable(tb.id, tb);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _confirmDeleteException(TimetableException ex) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCardBg,
        title: const Text('Delete Exception'),
        content: const Text('Are you sure you want to delete this exception? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: _isProcessing ? null : () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);
    try {
      await _firestore.deleteTimetableException(ex.id, ex);
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
        title: Text('${widget.faculty.name} Schedule'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.darkAccent,
          labelColor: AppTheme.darkAccent,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Timetables'),
            Tab(text: 'Exceptions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTimetablesTab(),
          _buildExceptionsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminTimetableFormScreen(faculty: widget.faculty),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminExceptionFormScreen(faculty: widget.faculty),
              ),
            );
          }
        },
        backgroundColor: AppTheme.darkAccent,
        child: const Icon(Icons.add_rounded, color: AppTheme.darkColor),
      ),
    );
  }

  Widget _buildTimetablesTab() {
    return StreamBuilder<List<Timetable>>(
      stream: _firestore.getTimetablesStream(widget.faculty.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final items = snapshot.data!;
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_month_rounded, size: 64, color: Colors.grey.shade700),
                const SizedBox(height: 16),
                const Text('No timetables found.', style: TextStyle(color: Colors.white54, fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final tb = items[index];
            return Card(
              color: AppTheme.darkCardBg,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                title: Text(
                  tb.term,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('${tb.slots.length} slots defined', style: const TextStyle(color: Colors.white54)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (tb.active)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withAlpha(100)),
                        ),
                        child: const Text('ACTIVE', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('INACTIVE', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                      onPressed: _isProcessing ? null : () => _confirmDeleteTimetable(tb),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminTimetableFormScreen(
                        faculty: widget.faculty,
                        existingTimetable: tb,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildExceptionsTab() {
    return StreamBuilder<List<TimetableException>>(
      stream: _firestore.getTimetableExceptionsStream(widget.faculty.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final items = snapshot.data!;
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy_rounded, size: 64, color: Colors.grey.shade700),
                const SizedBox(height: 16),
                const Text('No exceptions found.', style: TextStyle(color: Colors.white54, fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final ex = items[index];
            final dateStr = '${ex.date.year}-${ex.date.month.toString().padLeft(2, '0')}-${ex.date.day.toString().padLeft(2, '0')}';
            return Card(
              color: AppTheme.darkCardBg,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                title: Text(
                  dateStr,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  ex.type.toUpperCase() + (ex.note != null && ex.note!.isNotEmpty ? ' • ${ex.note}' : ''), 
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54)
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                  onPressed: _isProcessing ? null : () => _confirmDeleteException(ex),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminExceptionFormScreen(
                        faculty: widget.faculty,
                        existingException: ex,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
