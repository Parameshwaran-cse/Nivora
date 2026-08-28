import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

/// Provider for faculty directory state
class FacultyProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();

  List<Faculty> _faculty = [];
  List<Department> _departments = [];
  List<Designation> _designations = [];
  List<Location> _locations = [];

  bool _isLoading = false;
  String? _error;

  // Filters
  String? _selectedDepartmentId;
  String? _selectedDesignationId;
  String _searchQuery = '';

  // Getters
  List<Faculty> get faculty => _faculty;
  List<Department> get departments => _departments;
  List<Designation> get designations => _designations;
  List<Location> get locations => _locations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedDepartmentId => _selectedDepartmentId;
  String? get selectedDesignationId => _selectedDesignationId;
  String get searchQuery => _searchQuery;

  /// Filtered faculty list (client-side per SRD FR-2.5)
  List<Faculty> get filteredFaculty {
    var result = _faculty;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((f) => f.name.toLowerCase().contains(query)).toList();
    }

    if (_selectedDepartmentId != null) {
      result = result.where((f) => f.departmentId == _selectedDepartmentId).toList();
    }

    if (_selectedDesignationId != null) {
      result = result.where((f) => f.designationId == _selectedDesignationId).toList();
    }

    return result;
  }

  /// Get faculty strictly belonging to a specific department
  List<Faculty> getFacultyForDepartment(String departmentId) {
    return _faculty.where((f) => f.departmentId == departmentId).toList();
  }

  /// Load all reference data and faculty
  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _firestore.fetchAllFaculty(),
        _firestore.fetchAllDepartments(),
        _firestore.fetchAllDesignations(),
        _firestore.fetchAllLocations(),
      ]);

      _faculty = results[0] as List<Faculty>;
      _departments = results[1] as List<Department>;
      _designations = results[2] as List<Designation>;
      _locations = results[3] as List<Location>;
    } catch (e) {
      _error = 'Failed to load data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set department filter
  void setDepartmentFilter(String? departmentId) {
    _selectedDepartmentId = departmentId;
    notifyListeners();
  }

  /// Set designation filter
  void setDesignationFilter(String? designationId) {
    _selectedDesignationId = designationId;
    notifyListeners();
  }

  /// Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Clear all filters
  void clearFilters() {
    _selectedDepartmentId = null;
    _selectedDesignationId = null;
    _searchQuery = '';
    notifyListeners();
  }

  /// Check if any filter is active
  bool get hasActiveFilters =>
      _selectedDepartmentId != null ||
      _selectedDesignationId != null ||
      _searchQuery.isNotEmpty;

  /// Get department name by ID
  String? getDepartmentName(String departmentId) {
    try {
      return _departments.firstWhere((d) => d.id == departmentId).name;
    } catch (_) {
      return null;
    }
  }

  /// Get designation title by ID
  String? getDesignationTitle(String designationId) {
    try {
      return _designations.firstWhere((d) => d.id == designationId).title;
    } catch (_) {
      return null;
    }
  }

  /// Get location by ID
  Location? getLocation(String locationId) {
    try {
      return _locations.firstWhere((l) => l.id == locationId);
    } catch (_) {
      return null;
    }
  }
}