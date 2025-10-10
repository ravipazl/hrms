// lib/providers/requisition_provider.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hrms/models/requisition.dart';
import '../services/requisition_api_service.dart';

class RequisitionProvider with ChangeNotifier {
  final RequisitionApiService _apiService = RequisitionApiService();

  // Data
  List<Requisition> _requisitions = [];
  List<ReferenceData> _departments = [];
  List<ReferenceData> _genders = [];
  List<ReferenceData> _employmentTypes = [];
  List<ReferenceData> _requisitionTypes = [];
  List<ReferenceData> _newHireReasons = [];
  List<ReferenceData> _replacementReasons = [];

  // UI State
  bool _loading = false;
  bool _saving = false;
  bool _deleting = false;
  String? _error;
  
  // Filters
  String _searchQuery = '';
  String? _selectedDepartment;
  String? _selectedStatus;
  int _currentPage = 1;
  int _pageSize = 10;
  int _totalCount = 0;

  // Getters
  List<Requisition> get requisitions => _requisitions;
  List<ReferenceData> get departments => _departments;
  List<ReferenceData> get genders => _genders;
  List<ReferenceData> get employmentTypes => _employmentTypes;
  List<ReferenceData> get requisitionTypes => _requisitionTypes;
  List<ReferenceData> get newHireReasons => _newHireReasons;
  List<ReferenceData> get replacementReasons => _replacementReasons;
  
  bool get loading => _loading;
  bool get saving => _saving;
  bool get deleting => _deleting;
  String? get error => _error;
  
  String get searchQuery => _searchQuery;
  String? get selectedDepartment => _selectedDepartment;
  String? get selectedStatus => _selectedStatus;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalCount => _totalCount;
  int get totalPages => (_totalCount / _pageSize).ceil();

  /// Initialize provider with reference data
  Future<void> initialize() async {
    _loading = true;
    notifyListeners();

    try {
      print('🛠️ Initializing RequisitionProvider...');
      
      // Load all reference data in parallel
      await Future.wait([
        loadDepartments(),
        loadGenders(),
        loadEmploymentTypes(),
        loadRequisitionTypes(),
        loadNewHireReasons(),
        loadReplacementReasons(),
      ]);

      // Load initial requisitions
      await loadRequisitions();
      
      _error = null;
      print('✅ RequisitionProvider initialized successfully');
    } catch (e) {
      _error = 'Failed to initialize: $e';
      print('❌ Initialization error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Load requisitions with current filters
  Future<void> loadRequisitions({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
    }
    
    _loading = true;
    notifyListeners();

    try {
      print('📋 Loading requisitions (page $_currentPage)...');
      
      final result = await _apiService.getRequisitions(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        department: _selectedDepartment,
        status: _selectedStatus,
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (result['success'] == true) {
        _requisitions = result['results'] as List<Requisition>;
        _totalCount = result['count'] as int;
        _error = null;
        print('✅ Loaded ${_requisitions.length} requisitions');
      } else {
        // Handle API failure gracefully
        _requisitions = [];
        _totalCount = 0;
        _error = result['error']?.toString() ?? 'Failed to load requisitions';
        print('⚠️ API returned failure: $_error');
      }
    } catch (e) {
      _error = 'Failed to load requisitions: $e';
      _requisitions = [];
      _totalCount = 0;
      print('❌ Error loading requisitions: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Load reference data methods
  Future<void> loadDepartments() async {
    try {
      _departments = await _apiService.getReferenceData(9); // reference_type=9
      print('✅ Loaded ${_departments.length} departments');
    } catch (e) {
      print('❌ Error loading departments: $e');
      _departments = [];
    }
  }

  Future<void> loadGenders() async {
    try {
      _genders = await _apiService.getReferenceData(5); // reference_type=5
      print('✅ Loaded ${_genders.length} genders');
    } catch (e) {
      print('❌ Error loading genders: $e');
      _genders = [];
    }
  }

  Future<void> loadEmploymentTypes() async {
    try {
      _employmentTypes = await _apiService.getReferenceData(4); // reference_type=4
      print('✅ Loaded ${_employmentTypes.length} employment types');
    } catch (e) {
      print('❌ Error loading employment types: $e');
      _employmentTypes = [];
    }
  }

  Future<void> loadRequisitionTypes() async {
    try {
      _requisitionTypes = await _apiService.getReferenceData(1); // reference_type=1
      print('✅ Loaded ${_requisitionTypes.length} requisition types');
    } catch (e) {
      print('❌ Error loading requisition types: $e');
      _requisitionTypes = [];
    }
  }

  Future<void> loadNewHireReasons() async {
    try {
      _newHireReasons = await _apiService.getReferenceData(2); // reference_type=2
      print('✅ Loaded ${_newHireReasons.length} new hire reasons');
    } catch (e) {
      print('❌ Error loading new hire reasons: $e');
      _newHireReasons = [];
    }
  }

  Future<void> loadReplacementReasons() async {
    try {
      _replacementReasons = await _apiService.getReferenceData(3); // reference_type=3
      print('✅ Loaded ${_replacementReasons.length} replacement reasons');
    } catch (e) {
      print('❌ Error loading replacement reasons: $e');
      _replacementReasons = [];
    }
  }

  /// Get specific requisition by ID
  Future<Requisition?> getRequisition(int id) async {
    try {
      print('🔍 Loading requisition with ID: $id');
      
      // Clear any previous errors
      _error = null;
      
      final requisition = await _apiService.getRequisition(id);
      print('✅ Successfully loaded requisition: ${requisition.jobPosition}');
      return requisition;
    } catch (e) {
      print('❌ Error loading requisition $id: $e');
      
      // Set user-friendly error message
      if (e.toString().contains('404') || e.toString().contains('not found')) {
        _error = 'Requisition not found';
      } else if (e.toString().contains('network') || e.toString().contains('connection')) {
        _error = 'Network error. Please check your connection';
      } else {
        _error = 'Failed to load requisition. Please try again';
      }
      
      notifyListeners();
      return null;
    }
  }

  /// Create new requisition
  Future<bool> createRequisition(
    Requisition requisition, {
    File? jobDocument,
  }) async {
    _saving = true;
    _error = null;
    notifyListeners();

    try {
      // Validate first
      final errors = validateFormData(requisition);
      if (errors.isNotEmpty) {
        _error = errors.first;
        _saving = false;
        notifyListeners();
        return false;
      }

      final createdRequisition = await _apiService.createRequisition(
        requisition,
        jobDocument: jobDocument,
      );
      
      // Add to local list
      _requisitions.insert(0, createdRequisition);
      _totalCount++;
      
      print('✅ Requisition created successfully');
      _saving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to create requisition: $e';
      _saving = false;
      notifyListeners();
      print('❌ Error creating requisition: $e');
      return false;
    }
  }

  /// Update requisition
  Future<bool> updateRequisition(
    int id, 
    Requisition requisition, {
    File? jobDocument,
  }) async {
    _saving = true;
    _error = null;
    notifyListeners();

    try {
      // Validate first
      final errors = validateFormData(requisition);
      if (errors.isNotEmpty) {
        _error = errors.first;
        _saving = false;
        notifyListeners();
        return false;
      }

      final updatedRequisition = await _apiService.updateRequisition(
        id,
        requisition,
        jobDocument: jobDocument,
      );
      
      // Update in local list
      final index = _requisitions.indexWhere((req) => req.id == id);
      if (index != -1) {
        _requisitions[index] = updatedRequisition;
      }
      
      print('✅ Requisition updated successfully');
      _saving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update requisition: $e';
      _saving = false;
      notifyListeners();
      print('❌ Error updating requisition: $e');
      return false;
    }
  }

  /// Delete requisition
  Future<bool> deleteRequisition(int id) async {
    _deleting = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.deleteRequisition(id);
      
      // Remove from local list
      _requisitions.removeWhere((req) => req.id == id);
      _totalCount = (_totalCount - 1).clamp(0, _totalCount);
      
      print('✅ Requisition deleted successfully');
      _deleting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete requisition: $e';
      _deleting = false;
      notifyListeners();
      print('❌ Error deleting requisition: $e');
      return false;
    }
  }

  /// Update requisition status
  Future<bool> updateRequisitionStatus(int id, String status) async {
    try {
      await _apiService.updateRequisitionStatus(id, status);
      
      // Update in local list
      final index = _requisitions.indexWhere((req) => req.id == id);
      if (index != -1) {
        _requisitions[index] = _requisitions[index].copyWith(status: status);
      }
      
      print('✅ Requisition status updated successfully');
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update status: $e';
      notifyListeners();
      print('❌ Error updating status: $e');
      return false;
    }
  }

  /// Filter methods
  void setSearchQuery(String query) {
    _searchQuery = query;
    _currentPage = 1;
    notifyListeners();
  }

  void setDepartmentFilter(String? department) {
    _selectedDepartment = department;
    _currentPage = 1;
    notifyListeners();
  }

  void setStatusFilter(String? status) {
    _selectedStatus = status;
    _currentPage = 1;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedDepartment = null;
    _selectedStatus = null;
    _currentPage = 1;
    notifyListeners();
  }

  /// Pagination methods
  void setPage(int page) {
    _currentPage = page.clamp(1, totalPages);
    notifyListeners();
  }

  void nextPage() {
    if (_currentPage < totalPages) {
      _currentPage++;
      notifyListeners();
    }
  }

  void previousPage() {
    if (_currentPage > 1) {
      _currentPage--;
      notifyListeners();
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Validate form data
  List<String> validateFormData(Requisition requisition) {
    List<String> errors = [];
    
    if (requisition.jobPosition.trim().isEmpty) {
      errors.add('Job position is required');
    }
    
    if (requisition.department.trim().isEmpty) {
      errors.add('Department is required');
    }
    
    if (requisition.qualification.trim().isEmpty) {
      errors.add('Qualification is required');
    }
    
    if (requisition.experience.trim().isEmpty) {
      errors.add('Experience is required');
    }
    
    if (requisition.essentialSkills.trim().isEmpty) {
      errors.add('Essential skills are required');
    }
    
    if (requisition.positions.isEmpty) {
      errors.add('At least one position detail is required');
    }
    
    return errors;
  }

  /// Utility methods
  String getDepartmentName(String departmentId) {
    final dept = _departments.firstWhere(
      (d) => d.id.toString() == departmentId,
      orElse: () => ReferenceData(id: 0, referenceValue: 'Unknown'),
    );
    return dept.referenceValue;
  }

  String getGenderName(String genderId) {
    final gender = _genders.firstWhere(
      (g) => g.id.toString() == genderId,
      orElse: () => ReferenceData(id: 0, referenceValue: 'Not Specified'),
    );
    return gender.referenceValue;
  }

  String getEmploymentTypeName(String typeId) {
    final type = _employmentTypes.firstWhere(
      (t) => t.id.toString() == typeId,
      orElse: () => ReferenceData(id: 0, referenceValue: 'Unknown'),
    );
    return type.referenceValue;
  }

  String getRequisitionTypeName(String typeId) {
    final type = _requisitionTypes.firstWhere(
      (t) => t.id.toString() == typeId,
      orElse: () => ReferenceData(id: 0, referenceValue: 'Unknown'),
    );
    return type.referenceValue;
  }

  /// Test API connection
  Future<bool> testApiConnection() async {
    try {
      final result = await _apiService.testConnection();
      return result['success'] == true;
    } catch (e) {
      print('❌ API connection test failed: $e');
      return false;
    }
  }
}
