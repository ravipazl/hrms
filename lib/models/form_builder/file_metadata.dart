/// File metadata returned from backend after upload
class FileMetadata {
  final String name;
  final int size;
  final String type;
  final String storedPath;
  final String accessToken;
  final DateTime uploadedAt;

  FileMetadata({
    required this.name,
    required this.size,
    required this.type,
    required this.storedPath,
    required this.accessToken,
    required this.uploadedAt,
  });

  /// Create from JSON (backend response)
  factory FileMetadata.fromJson(Map<String, dynamic> json) { 
    return FileMetadata(
      name: json['name'] as String,
      size: json['size'] as int,
      type: json['type'] as String,
      storedPath: json['storedPath'] as String,
      accessToken: json['accessToken'] as String,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
    );
  }

  /// Convert to JSON (for form submission)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'size': size,
      'type': type,
      'storedPath': storedPath,
      'accessToken': accessToken,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }

  /// Format file size for display
  String get formattedSize {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Get file extension
  String get extension {
    final parts = name.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  /// Check if file is an image
  bool get isImage {
    return type.startsWith('image/') ||
        ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }

  /// Check if file is a PDF
  bool get isPdf {
    return type == 'application/pdf' || extension == 'pdf';
  }

  /// Check if file is a document
  bool get isDocument {
    return ['doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'rtf']
        .contains(extension);
  }
}
