import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/faculty.dart';
import '../../services/firestore_service.dart';
import '../../utils/theme.dart';
import 'admin_faculty_timetable_screen.dart';

class AdminTimetableFacultyListScreen extends StatefulWidget {
  const AdminTimetableFacultyListScreen({super.key});

  @override
  State<AdminTimetableFacultyListScreen> createState() => _AdminTimetableFacultyListScreenState();
}

class _AdminTimetableFacultyListScreenState extends State<AdminTimetableFacultyListScreen> {
  final _firestore = FirestoreService();
  
  Map<String, String> _deptMap = {};
  bool _isLoadingLookups = true;

  @override
  void initState() {
    super.initState();
    _loadLookups();
  }

  Future<void> _loadLookups() async {
    try {
      final depts = await _firestore.fetchAllDepartments();
      if (!mounted) return;
      setState(() {
        _deptMap = {for (var d in depts) d.id: d.shortCode};
        _isLoadingLookups = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoadingLookups = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Faculty'),
      ),
      body: _isLoadingLookups
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Faculty>>(
              stream: _firestore.getAdminFacultyStream(false),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final facultyList = snapshot.data!;
                if (facultyList.isEmpty) {
                  return const Center(
                    child: Text(
                      'No active faculty found.',
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: facultyList.length,
                  itemBuilder: (context, index) {
                    final fac = facultyList[index];
                    final deptName = _deptMap[fac.departmentId] ?? 'Unknown Dept';

                    return Card(
                      color: AppTheme.darkCardBg,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.white10,
                          backgroundImage: fac.photoUrl != null
                              ? CachedNetworkImageProvider(fac.photoUrl!)
                              : null,
                          child: fac.photoUrl == null
                              ? const Icon(Icons.person_rounded, color: Colors.white54)
                              : null,
                        ),
                        title: Text(
                          fac.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(deptName, style: const TextStyle(color: Colors.white54)),
                        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white24),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdminFacultyTimetableScreen(faculty: fac),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
