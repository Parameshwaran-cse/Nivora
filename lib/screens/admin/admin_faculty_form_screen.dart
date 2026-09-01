import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/faculty.dart';
import '../../models/department.dart';
import '../../models/designation.dart';
import '../../models/location.dart';
import '../../models/consent.dart';
import '../../models/visibility.dart' as model_visibility;
import '../../services/firestore_service.dart';
import '../../utils/theme.dart';

class AdminFacultyFormScreen extends StatefulWidget {
  final Faculty? existingFaculty;
  const AdminFacultyFormScreen({super.key, this.existingFaculty});

  @override
  State<AdminFacultyFormScreen> createState() => _AdminFacultyFormScreenState();
}

class _AdminFacultyFormScreenState extends State<AdminFacultyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirestoreService();
  bool _isSaving = false;
  bool _isLoadingLookups = true;

  List<Department> _departments = [];
  List<Designation> _designations = [];
  List<Location> _locations = [];

  // Controllers
  final _nameController = TextEditingController();
  final _cabinController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _consentMethodController = TextEditingController();
  final _consentCollectedByController = TextEditingController();

  // Dropdown values
  String? _selectedDeptId;
  String? _selectedDesigId;
  String? _selectedLocationId;

  // Image
  File? _imageFile;
  String? _existingPhotoUrl;

  // Consent & Visibility
  bool _consentGiven = false;
  bool _allowLiveStatus = false;
  bool _visName = true;
  bool _visPhoto = true;
  bool _visDept = true;
  bool _visCabin = true;
  bool _visPhone = false;
  bool _visEmail = true;

  @override
  void initState() {
    super.initState();
    _loadLookups();
    _populateFields();
  }

  void _populateFields() {
    if (widget.existingFaculty != null) {
      final fac = widget.existingFaculty!;
      _nameController.text = fac.name;
      _cabinController.text = fac.cabinNo;
      _emailController.text = fac.email ?? '';
      _phoneController.text = fac.phone ?? '';
      
      _selectedDeptId = fac.departmentId;
      _selectedDesigId = fac.designationId;
      _selectedLocationId = fac.locationId;
      
      _existingPhotoUrl = fac.photoUrl;

      // Consent
      _consentGiven = fac.consent.given;
      _allowLiveStatus = fac.consent.allowLiveStatus;
      _consentMethodController.text = fac.consent.method ?? '';
      _consentCollectedByController.text = fac.consent.collectedBy ?? '';

      // Visibility
      _visName = fac.visibility.name;
      _visPhoto = fac.visibility.photo;
      _visDept = fac.visibility.department;
      _visCabin = fac.visibility.cabinNo;
      _visPhone = fac.visibility.phone;
      _visEmail = fac.visibility.email;
    }
  }

  Future<void> _loadLookups() async {
    try {
      final depts = await _firestore.fetchAllDepartments();
      final desigs = await _firestore.fetchAllDesignations();
      final locs = await _firestore.fetchAllLocations();
      
      if (!mounted) return;
      setState(() {
        _departments = depts;
        _designations = desigs; // Stream is ordered by rank, fetchAll might need sorting if not from stream, but query in firestore_service has orderBy('rank')
        _locations = locs;
        _isLoadingLookups = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoadingLookups = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Client side compression
        maxWidth: 800,
        maxHeight: 800,
      );
      if (picked != null) {
        setState(() => _imageFile = File(picked.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedDeptId == null || _selectedDesigId == null) {
      _showError('Department and Designation are required.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? photoUrl = _existingPhotoUrl;
      
      // Upload new image if selected. Needs an ID, if new, create one first or upload with a random ID?
      // Since upload requires facultyId, we will generate doc ref first for creates inside service, 
      // but firestore_service takes the Faculty object.
      // So if new, we can generate a random ID for the photo path, or generate ID manually.
      // Let's generate a temporary unique ID for photo if new.
      final facultyId = widget.existingFaculty?.id ?? DateTime.now().millisecondsSinceEpoch.toString();

      if (_imageFile != null) {
        photoUrl = await _firestore.uploadFacultyPhoto(_imageFile!, facultyId);
      }

      final consent = Consent(
        given: _consentGiven,
        allowLiveStatus: _allowLiveStatus,
        method: _consentMethodController.text.trim().isEmpty ? null : _consentMethodController.text.trim(),
        collectedBy: _consentCollectedByController.text.trim().isEmpty ? null : _consentCollectedByController.text.trim(),
        dateGiven: _consentGiven && (widget.existingFaculty?.consent.given != true) ? DateTime.now() : widget.existingFaculty?.consent.dateGiven,
      );

      final visibility = model_visibility.Visibility(
        name: _visName,
        photo: _visPhoto,
        department: _visDept,
        cabinNo: _visCabin,
        phone: _visPhone,
        email: _visEmail,
      );

      final newFac = Faculty(
        id: widget.existingFaculty?.id ?? '', // Will be assigned by Firestore if new
        name: _nameController.text.trim(),
        departmentId: _selectedDeptId!,
        designationId: _selectedDesigId!,
        cabinNo: _cabinController.text.trim(),
        locationId: _selectedLocationId,
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        photoUrl: photoUrl,
        consent: consent,
        visibility: visibility,
        lastUpdated: DateTime.now(),
      );

      if (widget.existingFaculty != null) {
        await _firestore.updateFaculty(widget.existingFaculty!.id, newFac, widget.existingFaculty!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Faculty updated.'), backgroundColor: Colors.green));
          Navigator.pop(context);
        }
      } else {
        await _firestore.createFaculty(newFac);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Faculty created.'), backgroundColor: Colors.green));
          Navigator.pop(context);
        }
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingFaculty != null ? 'Edit Faculty' : 'New Faculty'),
        actions: [
          if (_isSaving)
            const Center(child: Padding(padding: EdgeInsets.only(right: 16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
          else
            IconButton(
              icon: const Icon(Icons.check_rounded, color: AppTheme.darkAccent),
              onPressed: _save,
            ),
        ],
      ),
      body: _isLoadingLookups
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Photo Section
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: AppTheme.darkCardBg,
                              backgroundImage: _imageFile != null
                                  ? FileImage(_imageFile!)
                                  : (_existingPhotoUrl != null ? CachedNetworkImageProvider(_existingPhotoUrl!) : null) as ImageProvider?,
                              child: _imageFile == null && _existingPhotoUrl == null
                                  ? const Icon(Icons.add_a_photo_rounded, size: 40, color: Colors.white54)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: AppTheme.darkAccent, shape: BoxShape.circle),
                                child: const Icon(Icons.edit_rounded, color: AppTheme.darkColor, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Basic Info
                    Text('Basic Information', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.darkAccent)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Full Name *'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Department *'),
                      initialValue: _selectedDeptId,
                      dropdownColor: AppTheme.darkCardBg,
                      items: _departments.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
                      onChanged: (v) => setState(() => _selectedDeptId = v),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Designation *'),
                      initialValue: _selectedDesigId,
                      dropdownColor: AppTheme.darkCardBg,
                      items: _designations.map((d) => DropdownMenuItem(value: d.id, child: Text(d.title))).toList(),
                      onChanged: (v) => setState(() => _selectedDesigId = v),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    
                    const SizedBox(height: 32),
                    Text('Contact & Location', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.darkAccent)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email Address *'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Phone Number'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cabinController,
                      decoration: const InputDecoration(labelText: 'Cabin / Office No'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Building Location (Optional)'),
                      initialValue: _selectedLocationId,
                      dropdownColor: AppTheme.darkCardBg,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('None')),
                        ..._locations.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name))),
                      ],
                      onChanged: (v) => setState(() => _selectedLocationId = v),
                    ),

                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withAlpha(25),
                        border: Border.all(color: Colors.redAccent.withAlpha(100)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Consent & Visibility', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.redAccent)),
                          const SizedBox(height: 8),
                          const Text('Configure privacy settings carefully.', style: TextStyle(color: Colors.white70)),
                          const Divider(height: 32, color: Colors.white24),
                          
                          SwitchListTile(
                            title: const Text('Publicly Visible (Consent Given)'),
                            subtitle: const Text('If off, this record is completely hidden from the directory.'),
                            value: _consentGiven,
                            activeThumbColor: Colors.redAccent,
                            onChanged: (v) => setState(() => _consentGiven = v),
                            contentPadding: EdgeInsets.zero,
                          ),
                          
                          if (_consentGiven) ...[
                            SwitchListTile(
                              title: const Text('Allow Live Status'),
                              value: _allowLiveStatus,
                              onChanged: (v) => setState(() => _allowLiveStatus = v),
                              contentPadding: EdgeInsets.zero,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _consentMethodController,
                              decoration: const InputDecoration(labelText: 'Consent Method (e.g. Email, Form)'),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _consentCollectedByController,
                              decoration: const InputDecoration(labelText: 'Collected By (Admin Name)'),
                            ),
                            const SizedBox(height: 24),
                            const Text('Field-Level Visibility', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            _buildVisToggle('Name', _visName, (v) => setState(() => _visName = v)),
                            _buildVisToggle('Photo', _visPhoto, (v) => setState(() => _visPhoto = v)),
                            _buildVisToggle('Department', _visDept, (v) => setState(() => _visDept = v)),
                            _buildVisToggle('Cabin / Office', _visCabin, (v) => setState(() => _visCabin = v)),
                            _buildVisToggle('Phone Number', _visPhone, (v) => setState(() => _visPhone = v)),
                            _buildVisToggle('Email Address', _visEmail, (v) => setState(() => _visEmail = v)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildVisToggle(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}
