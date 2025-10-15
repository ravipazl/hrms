import 'package:flutter/foundation.dart';
import '../models/form_builder/form_field.dart';
import '../models/form_builder/form_data.dart';
import '../models/form_builder/enhanced_header_config.dart';
import '../models/form_builder/form_template.dart';
import '../services/form_builder_api_service.dart';

class FormBuilderProvider extends ChangeNotifier {
  // ========== STATE ==========
  
  List<FormField> _fields = [];
  FormField? _selectedField;
  String _formTitle = 'Untitled Form';
  String _formDescription = '';
  HeaderConfig _headerConfig = HeaderConfig.defaultConfig();
  FormTemplate? _currentTemplate;
  
  // UI State
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  String _mode = 'builder'; // 'builder' or 'preview'
  
  // Undo/Redo stacks
  final List<FormData> _undoStack = [];
  final List<FormData> _redoStack = [];
  
  // API Service
  final FormBuilderAPIService _apiService = FormBuilderAPIService();

  // ========== GETTERS ==========
  
  List<FormField> get fields => List.unmodifiable(_fields);
  FormField? get selectedField => _selectedField;
  String get formTitle => _formTitle;
  String get formDescription => _formDescription;
  HeaderConfig get headerConfig => _headerConfig;
  FormTemplate? get currentTemplate => _currentTemplate;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  String get mode => _mode;
  bool get hasUnsavedChanges => _currentTemplate == null && _fields.isNotEmpty;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  bool get isNewForm => _currentTemplate == null;

  // ========== FORM OPERATIONS ==========

  /// Add field at position
  void addField(FieldType type, {int? position}) {
    _saveState(); // For undo
    
    final newField = FormField.createDefault(type);
    
    if (position != null && position >= 0 && position <= _fields.length) {
      _fields.insert(position, newField);
    } else {
      _fields.add(newField);
    }
    
    _selectedField = newField;
    notifyListeners();
  }

  /// Update field properties
  void updateField(String fieldId, Map<String, dynamic> updates) {
    final index = _fields.indexWhere((f) => f.id == fieldId);
    if (index == -1) return;
    
    final currentField = _fields[index];
    final updatedField = currentField.updateFromMap(updates);
    
    // Check if field actually changed to prevent unnecessary rebuilds
    if (_fieldsAreEqual(currentField, updatedField)) {
      return; // No actual change, skip notification
    }
    
    _saveState(); // For undo
    
    _fields[index] = updatedField;
    
    // Update selected field if it's the one being updated
    if (_selectedField?.id == fieldId) {
      _selectedField = _fields[index];
    }
    
    notifyListeners();
  }

  /// Helper to compare fields
  bool _fieldsAreEqual(FormField field1, FormField field2) {
    return field1.id == field2.id &&
           field1.label == field2.label &&
           field1.placeholder == field2.placeholder &&
           field1.required == field2.required &&
           field1.width == field2.width &&
           field1.height == field2.height &&
           _mapsAreEqual(field1.props, field2.props);
  }

  /// Helper to compare maps
  bool _mapsAreEqual(Map<String, dynamic> map1, Map<String, dynamic> map2) {
    if (map1.length != map2.length) return false;
    for (final key in map1.keys) {
      if (map1[key] != map2[key]) return false;
    }
    return true;
  }

  /// Delete field
  void deleteField(String fieldId) {
    _saveState();
    
    _fields.removeWhere((f) => f.id == fieldId);
    
    // Clear selection if deleted field was selected
    if (_selectedField?.id == fieldId) {
      _selectedField = null;
    }
    
    notifyListeners();
  }

  /// Duplicate field
  void duplicateField(String fieldId) {
    _saveState();
    
    final field = _fields.firstWhere((f) => f.id == fieldId);
    final index = _fields.indexWhere((f) => f.id == fieldId);
    
    final duplicatedField = FormField.fromJson(field.toJson());
    final newField = duplicatedField.copyWith(
      id: 'field_${DateTime.now().millisecondsSinceEpoch}_${fieldId.substring(6, 14)}',
      label: '${field.label} (Copy)',
    );
    
    _fields.insert(index + 1, newField);
    _selectedField = newField;
    
    notifyListeners();
  }

  /// Reorder fields
  void reorderFields(int oldIndex, int newIndex) {
    _saveState();
    
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    final field = _fields.removeAt(oldIndex);
    _fields.insert(newIndex, field);
    
    notifyListeners();
  }

  /// Select field
  void selectField(String? fieldId) {
    if (fieldId == null) {
      _selectedField = null;
    } else {
      try {
        _selectedField = _fields.firstWhere((f) => f.id == fieldId);
      } catch (e) {
        _selectedField = null;
      }
    }
    notifyListeners();
  }

  /// Update form title
  void updateFormTitle(String title) {
    _formTitle = title;
    notifyListeners();
  }

  /// Update form description
  void updateFormDescription(String description) {
    _formDescription = description;
    notifyListeners();
  }

  /// Update header config (Enhanced)
  void updateHeaderConfig(HeaderConfig config) {
    _saveState();
    _headerConfig = config;
    notifyListeners();
  }

  /// Update logo config
  void updateLogoConfig(LogoConfig logo) {
    _saveState();
    _headerConfig = _headerConfig.copyWith(logo: logo);
    notifyListeners();
  }

  /// Update title config
  void updateTitleConfig(TitleConfig title) {
    _saveState();
    _headerConfig = _headerConfig.copyWith(title: title);
    notifyListeners();
  }

  /// Update description config
  void updateDescriptionConfig(DescriptionConfig description) {
    _saveState();
    _headerConfig = _headerConfig.copyWith(description: description);
    notifyListeners();
  }

  /// Update styling config
  void updateStylingConfig(HeaderStyling styling) {
    _saveState();
    _headerConfig = _headerConfig.copyWith(styling: styling);
    notifyListeners();
  }

  /// Update layout config
  void updateLayoutConfig(LayoutConfig layout) {
    _saveState();
    _headerConfig = _headerConfig.copyWith(layout: layout);
    notifyListeners();
  }

  /// Add custom field
  void addCustomHeaderField(CustomHeaderField field) {
    _saveState();
    final updatedFields = List<CustomHeaderField>.from(_headerConfig.customFields);
    updatedFields.add(field);
    _headerConfig = _headerConfig.copyWith(customFields: updatedFields);
    notifyListeners();
  }

  /// Update custom field
  void updateCustomHeaderField(String fieldId, CustomHeaderField updatedField) {
    _saveState();
    final updatedFields = _headerConfig.customFields
        .map((f) => f.id == fieldId ? updatedField : f)
        .toList();
    _headerConfig = _headerConfig.copyWith(customFields: updatedFields);
    notifyListeners();
  }

  /// Remove custom field
  void removeCustomHeaderField(String fieldId) {
    _saveState();
    final updatedFields = _headerConfig.customFields
        .where((f) => f.id != fieldId)
        .toList();
    _headerConfig = _headerConfig.copyWith(customFields: updatedFields);
    notifyListeners();
  }

  /// Set mode (builder/preview)
  void setMode(String newMode) {
    _mode = newMode;
    notifyListeners();
  }

  // ========== UNDO/REDO ==========

  void _saveState() {
    final currentState = FormData(
      formTitle: _formTitle,
      formDescription: _formDescription,
      headerConfig: _headerConfig,
      fields: List.from(_fields),
    );
    
    _undoStack.add(currentState);
    _redoStack.clear(); // Clear redo stack on new action
    
    // Limit undo stack size
    if (_undoStack.length > 50) {
      _undoStack.removeAt(0);
    }
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    
    // Save current state to redo stack
    final currentState = FormData(
      formTitle: _formTitle,
      formDescription: _formDescription,
      headerConfig: _headerConfig,
      fields: List.from(_fields),
    );
    _redoStack.add(currentState);
    
    // Restore previous state
    final previousState = _undoStack.removeLast();
    _formTitle = previousState.formTitle;
    _formDescription = previousState.formDescription;
    _headerConfig = previousState.headerConfig;
    _fields = List.from(previousState.fields);
    _selectedField = null;
    
    notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    
    // Save current state to undo stack
    _saveState();
    
    // Restore next state
    final nextState = _redoStack.removeLast();
    _formTitle = nextState.formTitle;
    _formDescription = nextState.formDescription;
    _headerConfig = nextState.headerConfig;
    _fields = List.from(nextState.fields);
    _selectedField = null;
    
    notifyListeners();
  }

  // ========== API OPERATIONS ==========

  /// Load template from server
  Future<void> loadTemplate(String templateId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final template = await _apiService.getTemplate(templateId);
      final formData = await _apiService.loadTemplateForEditing(templateId);

      _currentTemplate = template;
      _formTitle = formData.formTitle;
      _formDescription = formData.formDescription;
      _headerConfig = formData.headerConfig;
      _fields = formData.fields;
      _selectedField = null;
      
      _undoStack.clear();
      _redoStack.clear();

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

/// Save template to server - UPDATED
Future<bool> saveTemplate() async {
  if (_isSaving) return false;
  
  _isSaving = true;
  _error = null;
  notifyListeners();

  try {
    final formData = FormData(
      formTitle: _formTitle,
      formDescription: _formDescription,
      headerConfig: _headerConfig,
      fields: _fields,
    );

    // ✅ Optional: Test data format before sending
    await _apiService.testDataFormat(formData);

    if (_currentTemplate != null) {
      // Update existing
      final updated = await _apiService.updateTemplate(
        _currentTemplate!.id,
        formData,
      );
      _currentTemplate = updated;
    } else {
      // Create new
      final created = await _apiService.saveTemplate(formData);
      _currentTemplate = created;
    }

    _error = null;
    return true;
  } catch (e) {
    _error = e.toString();
    return false;
  } finally {
    _isSaving = false;
    notifyListeners();
  }
}

  /// Reset form to empty state
  void resetForm() {
    _fields = [];
    _selectedField = null;
    _formTitle = 'Untitled Form';
    _formDescription = '';
    _headerConfig = HeaderConfig.defaultConfig();
    _currentTemplate = null;
    _error = null;
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
  }

  /// Import form from JSON
  void importForm(Map<String, dynamic> json) {
    _saveState();
    
    final formData = FormData.fromJson(json);
    _formTitle = formData.formTitle;
    _formDescription = formData.formDescription;
    _headerConfig = formData.headerConfig;
    _fields = formData.fields;
    _selectedField = null;
    
    notifyListeners();
  }

  /// Export form to JSON
  Map<String, dynamic> exportForm() {
    final formData = FormData(
      formTitle: _formTitle,
      formDescription: _formDescription,
      headerConfig: _headerConfig,
      fields: _fields,
    );
    return formData.toJson();
  }

  /// Get field by ID
  FormField? getFieldById(String fieldId) {
    try {
      return _fields.firstWhere((f) => f.id == fieldId);
    } catch (e) {
      return null;
    }
  }

  /// Update multiple fields at once
  void updateFields(List<FormField> newFields) {
    _saveState();
    _fields = List.from(newFields);
    notifyListeners();
  }
}
