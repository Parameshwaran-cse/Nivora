import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../utils/theme.dart';
import 'admin_location_form_screen.dart';

class AdminLocationsScreen extends StatefulWidget {
  const AdminLocationsScreen({super.key});

  @override
  State<AdminLocationsScreen> createState() => _AdminLocationsScreenState();
}

class _AdminLocationsScreenState extends State<AdminLocationsScreen> {
  final _firestore = FirestoreService();
  bool _isDeleting = false;

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _confirmDelete(Location loc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCardBg,
        title: const Text('Delete Location'),
        content: Text('Are you sure you want to delete "${loc.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: _isDeleting ? null : () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);
    try {
      await _firestore.deleteLocation(loc.id, loc);
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Locations'),
      ),
      body: StreamBuilder<List<Location>>(
        stream: _firestore.getLocationsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final locations = snapshot.data!;
          if (locations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.place_rounded, size: 64, color: Colors.grey.shade700),
                  const SizedBox(height: 16),
                  const Text(
                    'No locations found.\nTap + to add one.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          // Sort by building, then floor, then name
          locations.sort((a, b) {
            int cmp = a.building.compareTo(b.building);
            if (cmp != 0) return cmp;
            cmp = a.floor.compareTo(b.floor);
            if (cmp != 0) return cmp;
            return a.name.compareTo(b.name);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: locations.length,
            itemBuilder: (context, index) {
              final loc = locations[index];
              return Card(
                color: AppTheme.darkCardBg,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(
                    loc.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      '${loc.building} • ${loc.floor}',
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.darkAccent.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.darkAccent.withAlpha(100)),
                        ),
                        child: Text(
                          loc.type.toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.darkAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                        onPressed: _isDeleting ? null : () => _confirmDelete(loc),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminLocationFormScreen(existingLocation: loc),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminLocationFormScreen(),
            ),
          );
        },
        backgroundColor: AppTheme.darkAccent,
        child: const Icon(Icons.add_rounded, color: AppTheme.darkColor),
      ),
    );
  }
}
