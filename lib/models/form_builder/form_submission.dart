/// FormSubmission model - represents a submitted form response
class FormSubmission { 
  final String id;
  final String templateId;
  final Map<String, dynamic> formData;
  final Map<String, dynamic> metadata;
  final DateTime submittedAt;
  final String status;

  FormSubmission({
    required this.id,
    required this.templateId, 
    required this.formData,
    required this.metadata,
    required this.submittedAt,
    this.status = 'pending',
  });

  /// Create from JSON (API response)
  factory FormSubmission.fromJson(Map<String, dynamic> json) {
    return FormSubmission(
      id: json['id'] as String,
      templateId: json['template_id'] as String,
      formData: json['form_data'] as Map<String, dynamic>? ?? {},
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      submittedAt: DateTime.parse(json['submitted_at'] as String),
      status: json['status'] as String? ?? 'pending',
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

  /// Get submitter info from metadata
  String? get submitterEmail => metadata['email'] as String?;
  String? get submitterName => metadata['name'] as String?;
  String? get userAgent => metadata['userAgent'] as String?;
  String? get platform => metadata['platform'] as String?;
}
