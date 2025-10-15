import 'form_field.dart';
import 'enhanced_header_config.dart';

/// FormData - represents the complete form structure
class FormData {
  final String formTitle;
  final String formDescription;
  final HeaderConfig headerConfig;
  final List<FormField> fields;
  final String? name; // Unique name for saving

  FormData({
    required this.formTitle,
    required this.formDescription,
    required this.headerConfig,
    required this.fields,
    this.name,
  });

  /// Create default empty form
  factory FormData.empty() {
    return FormData(
      formTitle: 'Untitled Form',
      formDescription: '',
      headerConfig: HeaderConfig.defaultConfig(),
      fields: [],
    );
  }

  /// Create from JSON
  factory FormData.fromJson(Map<String, dynamic> json) {
    return FormData(
      formTitle: json['formTitle'] as String? ?? 'Untitled Form',
      formDescription: json['formDescription'] as String? ?? '',
      headerConfig:
          json['headerConfig'] != null
              ? HeaderConfig.fromJson(
                json['headerConfig'] as Map<String, dynamic>,
              )
              : HeaderConfig.defaultConfig(),
      fields:
          (json['fields'] as List<dynamic>?)
              ?.map(
                (fieldJson) =>
                    FormField.fromJson(fieldJson as Map<String, dynamic>),
              )
              .toList() ??
          [],
      name: json['name'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'formTitle': formTitle,
      'formDescription': formDescription,
      'headerConfig': headerConfig.toJson(),
      'fields': fields.map((field) => field.toJson()).toList(),
      if (name != null) 'name': name,
    };
  }

  /// Create a copy with modified properties
  FormData copyWith({
    String? formTitle,
    String? formDescription,
    HeaderConfig? headerConfig,
    List<FormField>? fields,
    String? name,
  }) {
    return FormData(
      formTitle: formTitle ?? this.formTitle,
      formDescription: formDescription ?? this.formDescription,
      headerConfig: headerConfig ?? this.headerConfig,
      fields: fields ?? List<FormField>.from(this.fields),
      name: name ?? this.name,
    );
  }

  /// Generate unique name from title
  String generateName() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final cleanTitle = formTitle
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .substring(0, formTitle.length > 50 ? 50 : formTitle.length);
    return '${cleanTitle}_$timestamp';
  }

  /// Validate form data integrity
  List<String> validate() {
    final errors = <String>[];

    if (formTitle.trim().isEmpty) {
      errors.add('Form title is required');
    }

    for (final field in fields) {
      final fieldErrors = field.validate();
      if (fieldErrors.isNotEmpty) {
        errors.addAll(fieldErrors.map((e) => 'Field ${field.label}: $e'));
      }
    }

    return errors;
  }

  /// Get field by ID
  FormField? getFieldById(String fieldId) {
    try {
      return fields.firstWhere((field) => field.id == fieldId);
    } catch (e) {
      return null;
    }
  }

  /// Get field index
  int getFieldIndex(String fieldId) {
    return fields.indexWhere((field) => field.id == fieldId);
  }

  /// Add field
  FormData addField(FormField field, {int? position}) {
    final newFields = List<FormField>.from(fields);
    if (position != null && position >= 0 && position <= newFields.length) {
      newFields.insert(position, field);
    } else {
      newFields.add(field);
    }
    return copyWith(fields: newFields); 
  }

  /// Update field
  FormData updateField(String fieldId, FormField updatedField) {
    final newFields =
        fields.map((field) {
          return field.id == fieldId ? updatedField : field;
        }).toList();
    return copyWith(fields: newFields);
  }

  /// Delete field
  FormData deleteField(String fieldId) {
    final newFields = fields.where((field) => field.id != fieldId).toList();
    return copyWith(fields: newFields);
  }

  /// Reorder fields
  FormData reorderFields(int oldIndex, int newIndex) {
    final newFields = List<FormField>.from(fields);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final field = newFields.removeAt(oldIndex);
    newFields.insert(newIndex, field);
    return copyWith(fields: newFields);
  }

  /// Duplicate field
  FormData duplicateField(String fieldId) {
    final field = getFieldById(fieldId);
    if (field == null) return this;

    final index = getFieldIndex(fieldId);
    final duplicatedField = FormField.fromJson(field.toJson())..copyWith(
      id:
          'field_${DateTime.now().millisecondsSinceEpoch}_${fieldId.substring(0, 8)}',
      label: '${field.label} (Copy)',
    );

    return addField(duplicatedField, position: index + 1);
  }
}
