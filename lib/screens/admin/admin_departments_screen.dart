import 'package:flutter/material.dart';
import '../../models/department.dart';
import '../../services/firestore_service.dart';
import '../../utils/theme.dart';

class AdminDepartmentsScreen extends StatefulWidget {
  const AdminDepartmentsScreen({super.key});

  @override
  State<AdminDepartmentsScreen> createState() => _AdminDepartmentsScreenState();
}

class _AdminDepartmentsScreenState extends State<AdminDepartmentsScreen> {
  final _firestore = FirestoreService();
  bool _isProcessing = false;

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _confirmDelete(Department dept) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCardBg,
        title: const Text('Confirm Delete'),
        content: Text('Delete ${dept.name}? This cannot be undone.'),
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
      await _firestore.deleteDepartment(dept.id, dept);
      _showSuccess('Department deleted.');
    } catch (e) {
      // e.toString() contains the exception message from FirestoreService
      final msg = e.toString().replaceAll('Exception: ', '');
      _showError(msg);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showDepartmentForm([Department? existingDept]) {
    final isEditing = existingDept != null;
    final nameController = TextEditingController(text: existingDept?.name);
    final shortCodeController = TextEditingController(text: existingDept?.shortCode);
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;
    final newDocId = isEditing ? existingDept.id : _firestore.generateId();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isEditing ? 'Edit Department' : 'New Department',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: shortCodeController,
                    decoration: const InputDecoration(labelText: 'Short Code (e.g. CSE)'),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setModalState(() => isSaving = true);

                            final newDept = Department(
                              id: newDocId,
                              name: nameController.text.trim(),
                              shortCode: shortCodeController.text.trim(),
                            );

                            try {
                              if (isEditing) {
                                await _firestore.updateDepartment(existingDept.id, newDept, existingDept);
                                _showSuccess('Department updated.');
                              } else {
                                await _firestore.createDepartment(newDept);
                                _showSuccess('Department created.');
                              }
                              if (context.mounted) Navigator.pop(context);
                            } catch (e) {
                              final msg = e.toString().replaceAll('Exception: ', '');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
                                );
                              }
                            } finally {
                              setModalState(() => isSaving = false);
                            }
                          },
                    child: isSaving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(isEditing ? 'Save Changes' : 'Create'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Departments'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDepartmentForm(),
        backgroundColor: AppTheme.darkAccent,
        child: const Icon(Icons.add_rounded, color: AppTheme.darkColor),
      ),
      body: StreamBuilder<List<Department>>(
        stream: _firestore.getDepartmentsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final depts = snapshot.data!;
          if (depts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business_rounded, size: 64, color: Colors.grey.shade700),
                  const SizedBox(height: 16),
                  const Text('No departments found.', style: TextStyle(color: Colors.white54, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: depts.length,
            itemBuilder: (context, index) {
              final dept = depts[index];
              return Card(
                color: AppTheme.darkCardBg,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  title: Text(
                    dept.name, 
                    maxLines: 2, 
                    overflow: TextOverflow.ellipsis, 
                    style: const TextStyle(fontWeight: FontWeight.bold)
                  ),
                  subtitle: Text(dept.shortCode, style: const TextStyle(color: Colors.white54)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, color: AppTheme.darkAccent, size: 20),
                        onPressed: () => _showDepartmentForm(dept),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                        onPressed: _isProcessing ? null : () => _confirmDelete(dept),
                      ),
                    ],
                  ),
                  onTap: () => _showDepartmentForm(dept),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
