import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/faculty.dart';
import '../../services/firestore_service.dart';
import '../../utils/theme.dart';
import 'admin_faculty_form_screen.dart';

class AdminFacultyScreen extends StatefulWidget {
  const AdminFacultyScreen({super.key});

  @override
  State<AdminFacultyScreen> createState() => _AdminFacultyScreenState();
}

class _AdminFacultyScreenState extends State<AdminFacultyScreen> {
  final _firestore = FirestoreService();
  bool _showArchived = false;
  
  Map<String, String> _deptMap = {};
  Map<String, String> _desigMap = {};
  bool _isLoadingLookups = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadLookups();
  }

  Future<void> _loadLookups() async {
    try {
      final depts = await _firestore.fetchAllDepartments();
      final desigs = await _firestore.fetchAllDesignations();
      if (!mounted) return;
      setState(() {
        _deptMap = {for (var d in depts) d.id: d.shortCode};
        _desigMap = {for (var d in desigs) d.id: d.title};
        _isLoadingLookups = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoadingLookups = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _confirmArchive(Faculty fac) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCardBg,
        title: const Text('Archive Faculty'),
        content: Text('Archive ${fac.name}? They will be removed from the public directory.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: _isProcessing ? null : () => Navigator.pop(context, true),
            child: const Text('Archive', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);
    try {
      await _firestore.softDeleteFaculty(fac.id);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _confirmRestore(Faculty fac) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCardBg,
        title: const Text('Restore Faculty'),
        content: Text('Restore ${fac.name}? They will reappear in the admin list (but consent will remain off).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: _isProcessing ? null : () => Navigator.pop(context, true),
            child: const Text('Restore', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);
    try {
      await _firestore.restoreFaculty(fac.id);
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
        title: Text(_showArchived ? 'Archived Faculty' : 'Faculty'),
        actions: [
          IconButton(
            icon: Icon(_showArchived ? Icons.visibility_off_rounded : Icons.archive_rounded),
            tooltip: _showArchived ? 'Show Active' : 'Show Archived',
            onPressed: () {
              setState(() {
                _showArchived = !_showArchived;
              });
            },
          ),
        ],
      ),
      floatingActionButton: _showArchived
          ? null
          : FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminFacultyFormScreen()),
                );
              },
              backgroundColor: AppTheme.darkAccent,
              child: const Icon(Icons.add_rounded, color: AppTheme.darkColor),
            ),
      body: _isLoadingLookups
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Faculty>>(
              stream: _firestore.getAdminFacultyStream(_showArchived),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final facultyList = snapshot.data!;
                if (facultyList.isEmpty) {
                  return Center(
                    child: Text(
                      _showArchived ? 'No archived faculty.' : 'No faculty found.',
                      style: const TextStyle(color: Colors.white54),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: facultyList.length,
                  itemBuilder: (context, index) {
                    final fac = facultyList[index];
                    final deptName = _deptMap[fac.departmentId] ?? 'Unknown Dept';
                    final desigName = _desigMap[fac.designationId] ?? 'Unknown Desig';

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
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                fac.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (fac.consent.given)
                              const Icon(Icons.visibility_rounded, color: Colors.green, size: 16)
                            else
                              const Icon(Icons.visibility_off_rounded, color: Colors.redAccent, size: 16),
                          ],
                        ),
                        subtitle: Text('$deptName • $desigName', style: const TextStyle(color: Colors.white54)),
                        trailing: _showArchived
                            ? IconButton(
                                icon: const Icon(Icons.restore_rounded, color: Colors.green),
                                onPressed: _isProcessing ? null : () => _confirmRestore(fac),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_rounded, color: AppTheme.darkAccent, size: 20),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AdminFacultyFormScreen(existingFaculty: fac),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.archive_rounded, color: Colors.orange, size: 20),
                                    onPressed: _isProcessing ? null : () => _confirmArchive(fac),
                                  ),
                                ],
                              ),
                        onTap: () {
                          if (!_showArchived) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AdminFacultyFormScreen(existingFaculty: fac),
                              ),
                            );
                          }
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
