import 'package:flutter/material.dart';
import '../../models/designation.dart';
import '../../services/firestore_service.dart';
import '../../utils/theme.dart';

class AdminDesignationsScreen extends StatefulWidget {
  const AdminDesignationsScreen({super.key});

  @override
  State<AdminDesignationsScreen> createState() => _AdminDesignationsScreenState();
}

class _AdminDesignationsScreenState extends State<AdminDesignationsScreen> {
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

  Future<void> _confirmDelete(Designation desig) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCardBg,
        title: const Text('Confirm Delete'),
        content: Text('Delete ${desig.title}? This cannot be undone.'),
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
      await _firestore.deleteDesignation(desig.id, desig);
      _showSuccess('Designation deleted.');
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      _showError(msg);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showDesignationForm([Designation? existingDesig]) {
    final isEditing = existingDesig != null;
    final titleController = TextEditingController(text: existingDesig?.title);
    final rankController = TextEditingController(text: existingDesig?.rank.toString());
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

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
                    isEditing ? 'Edit Designation' : 'New Designation',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: rankController,
                    decoration: const InputDecoration(labelText: 'Rank (Integer)'),
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Required';
                      final parsed = int.tryParse(val.trim());
                      if (parsed == null || parsed < 0) return 'Must be a positive integer';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setModalState(() => isSaving = true);

                            final newDesig = Designation(
                              id: existingDesig?.id ?? '',
                              title: titleController.text.trim(),
                              rank: int.parse(rankController.text.trim()),
                            );

                            try {
                              if (isEditing) {
                                await _firestore.updateDesignation(existingDesig.id, newDesig, existingDesig);
                                _showSuccess('Designation updated.');
                              } else {
                                await _firestore.createDesignation(newDesig);
                                _showSuccess('Designation created.');
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
        title: const Text('Designations'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDesignationForm(),
        backgroundColor: AppTheme.darkAccent,
        child: const Icon(Icons.add_rounded, color: AppTheme.darkColor),
      ),
      body: StreamBuilder<List<Designation>>(
        stream: _firestore.getDesignationsStream(), // Already ordered by rank in the query
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final desigs = snapshot.data!;
          if (desigs.isEmpty) {
            return const Center(child: Text('No designations found.', style: TextStyle(color: Colors.white54)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: desigs.length,
            itemBuilder: (context, index) {
              final desig = desigs[index];
              return Card(
                color: AppTheme.darkCardBg,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  title: Text(desig.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Rank: ${desig.rank}', style: const TextStyle(color: Colors.white54)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, color: AppTheme.darkAccent, size: 20),
                        onPressed: () => _showDesignationForm(desig),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                        onPressed: _isProcessing ? null : () => _confirmDelete(desig),
                      ),
                    ],
                  ),
                  onTap: () => _showDesignationForm(desig),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
