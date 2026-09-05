import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../utils/theme.dart';

class AdminLocationFormScreen extends StatefulWidget {
  final Location? existingLocation;

  const AdminLocationFormScreen({super.key, this.existingLocation});

  @override
  State<AdminLocationFormScreen> createState() => _AdminLocationFormScreenState();
}

class _AdminLocationFormScreenState extends State<AdminLocationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirestoreService();
  bool _isProcessing = false;
  String? _newDocId;

  late TextEditingController _nameController;
  late TextEditingController _buildingController;
  late TextEditingController _floorController;
  late TextEditingController _descController;
  String _selectedType = 'cabin-block'; // lab / cafeteria / dept / amenity / cabin-block

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingLocation?.name ?? '');
    _buildingController = TextEditingController(text: widget.existingLocation?.building ?? '');
    _floorController = TextEditingController(text: widget.existingLocation?.floor ?? '');
    _descController = TextEditingController(text: widget.existingLocation?.description ?? '');
    _selectedType = widget.existingLocation?.type ?? 'cabin-block';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _buildingController.dispose();
    _floorController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isProcessing = true);

    try {
      _newDocId ??= _firestore.generateId();

      final newLoc = Location(
        id: widget.existingLocation?.id ?? _newDocId!,
        name: _nameController.text.trim(),
        type: _selectedType,
        building: _buildingController.text.trim(),
        floor: _floorController.text.trim(),
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        mapX: widget.existingLocation?.mapX,
        mapY: widget.existingLocation?.mapY,
      );

      if (widget.existingLocation != null) {
        await _firestore.updateLocation(widget.existingLocation!.id, newLoc, widget.existingLocation!);
      } else {
        await _firestore.createLocation(newLoc);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingLocation == null ? 'New Location' : 'Edit Location'),
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
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Location Name *',
                prefixIcon: Icon(Icons.location_on_outlined, color: Colors.white54),
              ),
              style: const TextStyle(color: Colors.white),
              validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Type *',
                prefixIcon: Icon(Icons.category_rounded, color: Colors.white54),
              ),
              dropdownColor: AppTheme.darkCardBg,
              initialValue: _selectedType,
              items: const [
                DropdownMenuItem(value: 'cabin-block', child: Text('Cabin Block')),
                DropdownMenuItem(value: 'lab', child: Text('Laboratory')),
                DropdownMenuItem(value: 'dept', child: Text('Department')),
                DropdownMenuItem(value: 'cafeteria', child: Text('Cafeteria')),
                DropdownMenuItem(value: 'amenity', child: Text('Amenity')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedType = val);
                }
              },
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _buildingController,
              decoration: const InputDecoration(
                labelText: 'Building *',
                prefixIcon: Icon(Icons.business_rounded, color: Colors.white54),
                hintText: 'e.g. Block B',
                hintStyle: TextStyle(color: Colors.white24),
              ),
              style: const TextStyle(color: Colors.white),
              validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _floorController,
              decoration: const InputDecoration(
                labelText: 'Floor *',
                prefixIcon: Icon(Icons.layers_rounded, color: Colors.white54),
                hintText: 'e.g. 1st Floor',
                hintStyle: TextStyle(color: Colors.white24),
              ),
              style: const TextStyle(color: Colors.white),
              validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
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
