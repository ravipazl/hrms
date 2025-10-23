import 'package:flutter/foundation.dart';
import '../models/form_builder/form_template.dart';
import '../services/form_builder_api_service.dart';
import '../services/auth_service.dart';

/// Template List Provider - Manages form template list state
class TemplateListProvider extends ChangeNotifier {
  // API Service - injected via constructor
  late final FormBuilderAPIService _apiService;

  List<FormTemplate> _templates = [];
  List<FormTemplate> _filteredTemplates = [];
  String _searchQuery = '';
  bool _isLoading = false;
  String? _error;

  // Constructor with AuthService injection
  TemplateListProvider(AuthService authService) {
    _apiService = FormBuilderAPIService(authService);
  }

  // Getters
  List<FormTemplate> get templates => _filteredTemplates;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get templateCount => _filteredTemplates.length;
  int get totalTemplates => _templates.length;

  /// Load all templates
  Future<void> loadTemplates() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _templates = await _apiService.getTemplates();
      _applyFilter();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _templates = [];
      _filteredTemplates = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Search templates
  void searchTemplates(String query) {
    _searchQuery = query;
    _applyFilter();
    notifyListeners();
  }

  /// Apply search filter
  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredTemplates = List.from(_templates);
    } else {
      final lowerQuery = _searchQuery.toLowerCase();
      _filteredTemplates = _templates.where((template) {
        return (template.title?.toLowerCase() ?? '').contains(lowerQuery) ||
            (template.description?.toLowerCase() ?? '').contains(lowerQuery) ||
            (template.name?.toLowerCase() ?? '').contains(lowerQuery);
      }).toList();
    }
  }

  /// Delete template
  Future<bool> deleteTemplate(String templateId) async {
    try {
      await _apiService.deleteTemplate(templateId);
      _templates.removeWhere((t) => t.id == templateId);
      _applyFilter();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Refresh templates
  Future<void> refresh() async {
    await loadTemplates();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Sort templates
  void sortTemplates(String sortBy) {
    switch (sortBy) {
      case 'name':
        _filteredTemplates.sort(
          (a, b) => (a.title ?? '').compareTo(b.title ?? ''),
        );
        break;
      case 'date':
        _filteredTemplates.sort(
          (a, b) => (b.updatedAt ?? DateTime(0)).compareTo(a.updatedAt ?? DateTime(0)),
        );
        break;
      case 'submissions':
        _filteredTemplates.sort(
          (a, b) => (b.submissionCount ?? 0).compareTo(a.submissionCount ?? 0),
        );
        break;
      case 'views':
        _filteredTemplates.sort(
          (a, b) => (b.viewCount ?? 0).compareTo(a.viewCount ?? 0),
        );
        break;
    }
    notifyListeners();
  }
}
