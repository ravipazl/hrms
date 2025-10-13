import 'form_data.dart';

/// FormTemplate model - represents a saved form template in the database
class FormTemplate {
  final String id;
  final String name;
  final String title;
  final String description;
  final FormData reactFormData;
  final Map<String, dynamic> jsonSchema;
  final Map<String, dynamic> uiSchema;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final bool isPublished;
  final int viewCount;
  final int submissionCount;
  final bool authenticated;

  FormTemplate({
    required this.id,
    required this.name,
    required this.title,
    required this.description,
    required this.reactFormData,
    required this.jsonSchema,
    required this.uiSchema,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.isPublished = false,
    this.viewCount = 0,
    this.submissionCount = 0,
    this.authenticated = false,
  });

  /// Create from JSON (API response)
  factory FormTemplate.fromJson(Map<String, dynamic> json) {
    return FormTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      reactFormData: FormData.fromJson(json['react_form_data'] as Map<String, dynamic>),
      jsonSchema: json['json_schema'] as Map<String, dynamic>? ?? {},
      uiSchema: json['ui_schema'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
      isPublished: json['is_published'] as bool? ?? false,
      viewCount: json['view_count'] as int? ?? 0,
      submissionCount: json['submission_count'] as int? ?? 0,
      authenticated: json['authenticated'] as bool? ?? false,
    );
  }

  /// Convert to JSON (for API requests)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'title': title,
      'description': description,
      'react_form_data': reactFormData.toJson(),
      'json_schema': jsonSchema,
      'ui_schema': uiSchema,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive,
      'is_published': isPublished,
      'view_count': viewCount,
      'submission_count': submissionCount,
      'authenticated': authenticated,
    };
  }

  /// Get field count
  int get fieldsCount => reactFormData.fields.length;

  /// Get formatted date
  String get formattedCreatedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() > 1 ? 's' : ''} ago';
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

  /// Get formatted updated date
  String get formattedUpdatedDate {
    final now = DateTime.now();
    final difference = now.difference(updatedAt);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() > 1 ? 's' : ''} ago';
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

  /// Generate public form URL
  String getPublicFormUrl(String baseUrl) {
    return '$baseUrl/public/form/$id';
  }
}
