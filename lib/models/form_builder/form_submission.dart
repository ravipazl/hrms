/// FormSubmission model - represents a submitted form response
/// ENHANCED VERSION - With complete template structure support

import 'package:flutter/foundation.dart';
import 'form_template.dart';

class FormSubmission { 
  final String id;
  final String templateId;
  final Map<String, dynamic> formData;
  final Map<String, dynamic> metadata;
  final DateTime submittedAt;
  final String status;
  final String? submittedById;
  final String? submittedByName;
  final String? submittedByEmail;
  final List<String> validationErrors;
  
  // ADDED: Complete template structure for proper rendering
  final FormTemplate? template;

  FormSubmission({
    required this.id,
    required this.templateId, 
    required this.formData,
    required this.metadata,
    required this.submittedAt,
    this.status = 'pending',
    this.submittedById,
    this.submittedByName,
    this.submittedByEmail,
    this.validationErrors = const [],
    this.template,
  });

  /// Create from JSON (API response) - FIXED for backend consistency
  factory FormSubmission.fromJson(Map<String, dynamic> json) {
    debugPrint('📥 Parsing FormSubmission from JSON');
    debugPrint('📥 JSON keys: ${json.keys.toList()}');
    
    // Backend always returns consistent structure: data.form_data and data.metadata
    final dataObject = json['data'] as Map<String, dynamic>? ?? {};
    final formData = Map<String, dynamic>.from(dataObject['form_data'] as Map? ?? {});
    final metadata = Map<String, dynamic>.from(dataObject['metadata'] as Map? ?? {});
    
    debugPrint('📥 Data object keys: ${dataObject.keys.toList()}');
    debugPrint('📥 Form data keys: ${formData.keys.toList()}');
    
    // FIXED: Extract template ID - handle both string and object
    String templateId;
    final templateField = json['template_id'] ?? json['template'];
    
    if (templateField is String) {
      templateId = templateField;
    } else if (templateField is Map) {
      // If template is an object, extract the ID
      templateId = (templateField as Map<String, dynamic>)['id']?.toString() ?? '';
    } else {
      debugPrint('⚠️ Warning: template_id/template field is neither String nor Map: ${templateField.runtimeType}');
      templateId = '';
    }
    
    debugPrint('📥 Template ID: $templateId');
    
    // Extract submitter info from submitted_by object
    final submittedBy = json['submitted_by'] as Map<String, dynamic>?;
    final submittedById = submittedBy?['id']?.toString();
    final submittedByName = submittedBy?['full_name'] as String? ?? submittedBy?['username'] as String?;
    final submittedByEmail = submittedBy?['email'] as String?;
    
    // FIXED: Parse complete template structure
    FormTemplate? template;
    final templateData = json['template'];
    
    if (templateData is Map<String, dynamic>) {
      try {
        debugPrint('📥 Parsing template structure...');
        template = FormTemplate.fromJson(templateData);
        debugPrint('✅ Template parsed successfully: ${template.title}');
      } catch (e, stackTrace) {
        debugPrint('⚠️ Warning: Could not parse template structure: $e');
        debugPrint('Stack trace: $stackTrace');
        debugPrint('Template data: $templateData');
      }
    } else if (templateData is String) {
      debugPrint('📥 Template is a string ID, not an object. Will need to fetch separately.');
    } else {
      debugPrint('⚠️ Template field is neither Map nor String: ${templateData?.runtimeType}');
    }
    
    return FormSubmission(
      id: json['id'] as String,
      templateId: templateId,
      formData: formData,
      metadata: metadata,
      submittedAt: DateTime.parse(json['submitted_at'] as String),
      status: json['status'] as String? ?? 'pending',
      submittedById: submittedById,
      submittedByName: submittedByName,
      submittedByEmail: submittedByEmail,
      validationErrors: (json['validation_errors'] as List?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      template: template,
    );
  }


  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'template_id': templateId,
      'form_data': formData,
      'metadata': metadata,
      'submitted_at': submittedAt.toIso8601String(),
      'status': status,
      'validation_errors': validationErrors,
      if (template != null) 'template': template!.toJson(),
    };
  }

  /// Get formatted submission date
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(submittedAt);

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

  /// Get submitter info from metadata (legacy support)
  String? get submitterEmail => submittedByEmail ?? metadata['email'] as String?;
  String? get submitterName => submittedByName ?? metadata['name'] as String?;
  String? get userAgent => metadata['userAgent'] as String? ?? metadata['user_agent'] as String?;
  String? get platform => metadata['platform'] as String?;
  String? get ipAddress => metadata['ipAddress'] as String? ?? metadata['ip_address'] as String?;
  
  /// Get submission type
  String get submissionType => metadata['submissionType'] as String? ?? 
                               metadata['submission_type'] as String? ?? 
                               'unknown';
  
  /// Check if submission is from anonymous user
  bool get isAnonymous => submittedById == null;
  
  /// Get display name for submitter
  String get displayName {
    if (submittedByName != null && submittedByName!.isNotEmpty) {
      return submittedByName!;
    }
    if (submittedByEmail != null && submittedByEmail!.isNotEmpty) {
      return submittedByEmail!;
    }
    return 'Anonymous';
  }
}
