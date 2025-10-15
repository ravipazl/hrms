import 'package:uuid/uuid.dart';

import 'form_data.dart'; 

/// FormTemplate model - represents a saved form template in the database
/// Handles both partial responses (save/update) and full template data
class FormTemplate {
  final String id;
  final String name;
  final String title;
  final String? description;
  final FormData? reactFormData;
  final Map<String, dynamic>? jsonSchema;
  final Map<String, dynamic>? uiSchema;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final bool isPublished;
  final int viewCount;
  final int submissionCount;
  final bool authenticated;
  final String? createdBy;
  final Map<String, dynamic>? metadata;

  FormTemplate({
    required this.id,
    required this.name,
    required this.title,
    this.description,
    this.reactFormData,
    this.jsonSchema,
    this.uiSchema,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.isPublished = false,
    this.viewCount = 0,
    this.submissionCount = 0,
    this.authenticated = false,
    this.createdBy,
    this.metadata,
  });

  /// Create from JSON (API response) - Handles both partial and full responses
  factory FormTemplate.fromJson(Map<String, dynamic> json) {
    try {
      // Extract ID from multiple possible fields
      final id = _extractId(json);

      // Extract name and title with fallbacks
      final name = _extractName(json);
      final title = _extractTitle(json);

      // Extract dates safely
      final createdAt = _parseDateTime(json['created_at']);
      final updatedAt = _parseDateTime(
        json['updated_at'] ?? json['created_at'],
      );

      // Extract form data if available
      final reactFormData = _extractFormData(json);

      // Extract schemas
      final jsonSchema = _extractJsonSchema(json);
      final uiSchema = _extractUiSchema(json);

      // Extract statistics
      final viewCount = _extractViewCount(json);
      final submissionCount = _extractSubmissionCount(json);

      // Extract metadata
      final metadata = _extractMetadata(json);

      return FormTemplate(
        id: id,
        name: name,
        title: title,
        description: json['description']?.toString(),
        reactFormData: reactFormData,
        jsonSchema: jsonSchema,
        uiSchema: uiSchema,
        createdAt: createdAt,
        updatedAt: updatedAt,
        isActive: json['is_active'] as bool? ?? true,
        isPublished: json['is_published'] as bool? ?? false,
        viewCount: viewCount,
        submissionCount: submissionCount,
        authenticated: json['authenticated'] as bool? ?? false,
        createdBy: json['created_by']?.toString(),
        metadata: metadata,
      );
    } catch (e, stackTrace) {
      print('❌ Error parsing FormTemplate from JSON: $e');
      print('Stack trace: $stackTrace');
      print('JSON data: $json');
      rethrow;
    }
  }

  // ========== PRIVATE HELPER METHODS ==========

  static String _extractId(Map<String, dynamic> json) {
    return json['template_id']?.toString() ??
        json['id']?.toString() ??
        _generateTempId();
  }

  static String _extractName(Map<String, dynamic> json) {
    return json['name']?.toString() ??
        json['title']?.toString()?.toLowerCase().replaceAll(' ', '_') ??
        'untitled_form_${DateTime.now().millisecondsSinceEpoch}';
  }

  static String _extractTitle(Map<String, dynamic> json) {
    return json['title']?.toString() ??
        json['formTitle']?.toString() ??
        'Untitled Form';
  }

  static FormData? _extractFormData(Map<String, dynamic> json) {
    try {
      if (json['react_form_data'] != null) {
        return FormData.fromJson(
          json['react_form_data'] as Map<String, dynamic>,
        );
      }

      // Alternative: check if we have the structure at root level
      if (json['formTitle'] != null && json['fields'] != null) {
        return FormData.fromJson(json);
      }

      return null;
    } catch (e) {
      print('⚠️ Warning: Could not parse react_form_data: $e');
      return null;
    }
  }

  static Map<String, dynamic>? _extractJsonSchema(Map<String, dynamic> json) {
    try {
      return json['json_schema'] as Map<String, dynamic>? ?? {};
    } catch (e) {
      print('⚠️ Warning: Could not parse json_schema: $e');
      return {};
    }
  }

  static Map<String, dynamic>? _extractUiSchema(Map<String, dynamic> json) {
    try {
      return json['ui_schema'] as Map<String, dynamic>? ?? {};
    } catch (e) {
      print('⚠️ Warning: Could not parse ui_schema: $e');
      return {};
    }
  }

  static int _extractViewCount(Map<String, dynamic> json) {
    try {
      return (json['view_count'] as int?) ??
          (json['statistics'] != null
              ? (json['statistics']['view_count'] as int?)
              : null) ??
          0;
    } catch (e) {
      return 0;
    }
  }

  static int _extractSubmissionCount(Map<String, dynamic> json) {
    try {
      return (json['submission_count'] as int?) ??
          (json['statistics'] != null
              ? (json['statistics']['submission_count'] as int?)
              : null) ??
          0;
    } catch (e) {
      return 0;
    }
  }

  static Map<String, dynamic>? _extractMetadata(Map<String, dynamic> json) {
    try {
      final metadata = <String, dynamic>{};

      // Extract template metadata if present
      if (json['templateMetadata'] != null) {
        metadata.addAll(json['templateMetadata'] as Map<String, dynamic>);
      }

      // Extract statistics if present
      if (json['statistics'] != null) {
        metadata['statistics'] = json['statistics'];
      }

      // Extract field count
      final fieldCount =
          json['field_count'] ??
          (json['statistics'] != null
              ? (json['statistics']['field_count'] as int?)
              : null);
      if (fieldCount != null) {
        metadata['field_count'] = fieldCount;
      }

      return metadata.isNotEmpty ? metadata : null;
    } catch (e) {
      return null;
    }
  }

  static DateTime? _parseDateTime(dynamic date) {
    if (date == null) return null;

    try {
      if (date is DateTime) return date;
      if (date is String) return DateTime.parse(date);
      if (date is int) return DateTime.fromMillisecondsSinceEpoch(date);
      return null;
    } catch (e) {
      print('⚠️ Warning: Could not parse date: $date, error: $e');
      return null;
    }
  }

  static String _generateTempId() {
    // Use UUID to ensure consistent unique IDs across environments
    return 'temp_${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4()}';
  }

  // ========== PUBLIC METHODS ==========

  /// Convert to JSON (for API requests)
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'name': name,
      'title': title,
      'is_active': isActive,
      'is_published': isPublished,
      'view_count': viewCount,
      'submission_count': submissionCount,
      'authenticated': authenticated,
    };

    // Add optional fields only if they exist
    if (description != null) json['description'] = description;
    if (reactFormData != null)
      json['react_form_data'] = reactFormData!.toJson();
    if (jsonSchema != null && jsonSchema!.isNotEmpty)
      json['json_schema'] = jsonSchema;
    if (uiSchema != null && uiSchema!.isNotEmpty) json['ui_schema'] = uiSchema;
    if (createdAt != null) json['created_at'] = createdAt!.toIso8601String();
    if (updatedAt != null) json['updated_at'] = updatedAt!.toIso8601String();
    if (createdBy != null) json['created_by'] = createdBy;
    if (metadata != null && metadata!.isNotEmpty) json['metadata'] = metadata;

    return json;
  }

  /// Create a copy with modified properties
  FormTemplate copyWith({
    String? id,
    String? name,
    String? title,
    String? description,
    FormData? reactFormData,
    Map<String, dynamic>? jsonSchema,
    Map<String, dynamic>? uiSchema,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    bool? isPublished,
    int? viewCount,
    int? submissionCount,
    bool? authenticated,
    String? createdBy,
    Map<String, dynamic>? metadata,
  }) {
    return FormTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      description: description ?? this.description,
      reactFormData: reactFormData ?? this.reactFormData,
      jsonSchema: jsonSchema ?? this.jsonSchema,
      uiSchema: uiSchema ?? this.uiSchema,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      isPublished: isPublished ?? this.isPublished,
      viewCount: viewCount ?? this.viewCount,
      submissionCount: submissionCount ?? this.submissionCount,
      authenticated: authenticated ?? this.authenticated,
      createdBy: createdBy ?? this.createdBy,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Merge with another template (useful for updating partial data)
  FormTemplate mergeWith(FormTemplate other) {
    return copyWith(
      name: other.name != name ? other.name : null,
      title: other.title != title ? other.title : null,
      description: other.description != description ? other.description : null,
      reactFormData:
          other.reactFormData != reactFormData ? other.reactFormData : null,
      jsonSchema: other.jsonSchema != jsonSchema ? other.jsonSchema : null,
      uiSchema: other.uiSchema != uiSchema ? other.uiSchema : null,
      createdAt: other.createdAt != createdAt ? other.createdAt : null,
      updatedAt: other.updatedAt != updatedAt ? other.updatedAt : null,
      isActive: other.isActive != isActive ? other.isActive : null,
      isPublished: other.isPublished != isPublished ? other.isPublished : null,
      viewCount: other.viewCount != viewCount ? other.viewCount : null,
      submissionCount:
          other.submissionCount != submissionCount
              ? other.submissionCount
              : null,
      authenticated:
          other.authenticated != authenticated ? other.authenticated : null,
      createdBy: other.createdBy != createdBy ? other.createdBy : null,
      metadata: other.metadata != metadata ? other.metadata : null,
    );
  }

  // ========== GETTERS & PROPERTIES ==========

  /// Get field count - handles null reactFormData
  int get fieldsCount =>
      reactFormData?.fields.length ?? (metadata?['field_count'] as int?) ?? 0;

  /// Check if this is a complete template (has form data) or just a summary
  bool get isComplete => reactFormData != null;

  /// Check if this is a temporary template (not saved to server)
  bool get isTemporary => id.startsWith('temp_');

  /// Get the template statistics
  Map<String, dynamic> get statistics {
    return {
      'field_count': fieldsCount,
      'view_count': viewCount,
      'submission_count': submissionCount,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      ...?metadata?['statistics'],
    };
  }

  /// Get template status
  String get status {
    if (!isActive) return 'Inactive';
    if (isPublished) return 'Published';
    return 'Draft';
  }

  /// Get template status color (for UI)
  String get statusColor {
    if (!isActive) return '#ff6b6b'; // Red
    if (isPublished) return '#51cf66'; // Green
    return '#ffd43b'; // Yellow
  }

  // ========== DATE FORMATTING ==========

  /// Get formatted created date
  String get formattedCreatedDate {
    if (createdAt == null) return 'Unknown date';
    return _formatDateTime(createdAt!);
  }

  /// Get formatted updated date
  String get formattedUpdatedDate {
    if (updatedAt == null) return 'Unknown date';
    return _formatDateTime(updatedAt!);
  }

  /// Get relative time (e.g., "2 hours ago")
  String get relativeTime {
    final date = updatedAt ?? createdAt;
    if (date == null) return 'Unknown';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  static String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      // Today
      return 'Today at ${_formatTime(date)}';
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday at ${_formatTime(date)}';
    } else if (difference.inDays < 7) {
      // This week
      return '${_formatWeekday(date)} at ${_formatTime(date)}';
    } else {
      // Older
      return '${_formatDate(date)} at ${_formatTime(date)}';
    }
  }

  static String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static String _formatWeekday(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[date.weekday - 1];
  }

  // ========== URL GENERATION ==========

  /// Generate public form URL
  String getPublicFormUrl(String baseUrl) {
    return '$baseUrl/public/form/$id';
  }

  /// Generate edit form URL
  String getEditFormUrl(String baseUrl) {
    return '$baseUrl/builder/$id';
  }

  /// Generate preview form URL
  String getPreviewFormUrl(String baseUrl) {
    return '$baseUrl/preview/$id';
  }

  // ========== VALIDATION ==========

  /// Validate template data
  List<String> validate() {
    final errors = <String>[];

    if (id.isEmpty) {
      errors.add('Template ID is required');
    }

    if (name.isEmpty) {
      errors.add('Template name is required');
    }

    if (title.isEmpty) {
      errors.add('Template title is required');
    }

    if (reactFormData != null) {
      final formErrors = reactFormData!.validate();
      errors.addAll(formErrors);
    }

    return errors;
  }

  /// Check if template is valid
  bool get isValid => validate().isEmpty;

  // ========== UTILITY METHODS ==========

  /// Create an empty template
  factory FormTemplate.empty() {
    return FormTemplate(
      id: _generateTempId(),
      name: 'untitled_form_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Untitled Form',
      description: '',
      reactFormData: FormData.empty(),
      jsonSchema: {},
      uiSchema: {},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Create from FormData
  factory FormTemplate.fromFormData(FormData formData, {String? id}) {
    return FormTemplate(
      id: id ?? _generateTempId(),
      name: formData.name ?? formData.generateName(),
      title: formData.formTitle,
      description: formData.formDescription,
      reactFormData: formData,
      jsonSchema: {},
      uiSchema: {},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Convert to FormData
  FormData toFormData() {
    return reactFormData ??
        FormData.empty().copyWith(
          formTitle: title,
          formDescription: description ?? '',
          name: name,
        );
  }

  @override
  String toString() {
    return 'FormTemplate(id: $id, name: $name, title: $title, fields: $fieldsCount, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FormTemplate && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
