// lib/models/file_preview.dart

import 'dart:io';
import 'package:file_picker/file_picker.dart';

/// Model class for file preview information
/// Supports both new uploads and existing files from server
class FilePreview {
  final String name;
  final int size;
  final String type; // 'pdf', 'image', 'document'
  final String? url;
  final String? path; // Backend path (for existing files)
  final bool isNew;
  final bool isExisting;
  final File? file; // For mobile platforms
  final PlatformFile? platformFile; // For web platform

  FilePreview({
    required this.name,
    required this.size,
    required this.type,
    this.url,
    this.path,
    this.isNew = false,
    this.isExisting = false,
    this.file,
    this.platformFile,
  });

  /// Create FilePreview from a File object (mobile)
  factory FilePreview.fromFile(File file) {
    final fileName = file.path.split('/').last;
    final fileExtension = _getFileExtension(fileName).toLowerCase();
    
    return FilePreview(
      name: fileName,
      size: file.lengthSync(),
      type: _getFileType(fileExtension),
      url: file.path,
      isNew: true,
      isExisting: false,
      file: file,
    );
  }

  /// Create FilePreview from a PlatformFile (web)
  factory FilePreview.fromPlatformFile(PlatformFile platformFile) {
    final fileExtension = _getFileExtension(platformFile.name).toLowerCase();
    
    return FilePreview(
      name: platformFile.name,
      size: platformFile.size,
      type: _getFileType(fileExtension),
      url: null, // Will be generated as blob URL when needed
      isNew: true,
      isExisting: false,
      platformFile: platformFile,
    );
  }

  /// Create FilePreview from server data (edit mode)
  /// ENHANCED: Better parsing of server file data
  factory FilePreview.fromServer(Map<String, dynamic> json) {
    print('🔧 FilePreview.fromServer - Input: $json');
    
    // Extract filename from various possible fields
    String fileName = json['name'] ?? json['filename'] ?? json['file_name'] ?? '';
    String filePath = json['path'] ?? json['file'] ?? '';
    String fileUrl = json['url'] ?? '';
    
    print('   - Initial fileName: "$fileName"');
    print('   - Initial filePath: "$filePath"');
    print('   - Initial fileUrl: "$fileUrl"');
    
    // Construct full URL from path if needed
    if (fileUrl.isEmpty && filePath.isNotEmpty) {
      if (filePath.startsWith('http://') || filePath.startsWith('https://')) {
        fileUrl = filePath;
      } else if (filePath.startsWith('/media/')) {
        fileUrl = 'http://127.0.0.1:8000$filePath';
      } else if (filePath.startsWith('media/')) {
        fileUrl = 'http://127.0.0.1:8000/$filePath';
      } else {
        fileUrl = 'http://127.0.0.1:8000/media/$filePath';
      }
    }
    
    // Extract filename from URL if fileName is empty
    if (fileName.isEmpty && fileUrl.isNotEmpty) {
      final urlParts = fileUrl.split('/');
      if (urlParts.isNotEmpty) {
        fileName = urlParts.last.split('?').first; // Remove query params
      }
    }
    
    // Decode URL-encoded filename
    if (fileName.isNotEmpty) {
      try {
        fileName = Uri.decodeComponent(fileName);
      } catch (e) {
        print('   - Could not decode filename: $e');
      }
    }
    
    // Final fallback for filename
    if (fileName.isEmpty) {
      fileName = 'Document';
    }
    
    final fileExtension = _getFileExtension(fileName).toLowerCase();
    final fileType = _getFileType(fileExtension);
    final fileSize = json['size'] is int ? json['size'] as int : 0;
    
    print('   ✅ Parsed file:');
    print('      - Name: "$fileName"');
    print('      - URL: "$fileUrl"');
    print('      - Path: "$filePath"');
    print('      - Type: "$fileType"');
    print('      - Size: $fileSize');
    
    return FilePreview(
      name: fileName,
      size: fileSize,
      type: fileType,
      url: fileUrl,
      path: filePath.isNotEmpty ? filePath : null,
      isNew: false,
      isExisting: true,
    );
  }

  /// Helper method to get file extension
  static String _getFileExtension(String fileName) {
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot != -1 && lastDot < fileName.length - 1) {
      return fileName.substring(lastDot + 1);
    }
    return '';
  }

  /// Helper method to determine file type from extension
  static String _getFileType(String extension) {
    if (extension == 'pdf') {
      return 'pdf';
    } else if (['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(extension)) {
      return 'image';
    } else {
      return 'document';
    }
  }

  /// Format file size for display
  String get formattedSize {
    if (size == 0) return 'Unknown size';
    const suffixes = ['Bytes', 'KB', 'MB', 'GB'];
    var i = 0;
    double fileSize = size.toDouble();
    while (fileSize >= 1024 && i < suffixes.length - 1) {
      fileSize /= 1024;
      i++;
    }
    return '${fileSize.toStringAsFixed(fileSize < 10 ? 1 : 0)} ${suffixes[i]}';
  }

  /// Convert to JSON for API submission
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'size': size,
      'type': type,
      'url': url,
      'path': path,
      'isExisting': isExisting,
    };
  }

  @override
  String toString() {
    return 'FilePreview(name: $name, size: ${formattedSize}, type: $type, isNew: $isNew, isExisting: $isExisting, url: $url)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FilePreview &&
        other.name == name &&
        other.url == url &&
        other.path == path;
  }

  @override
  int get hashCode => name.hashCode ^ url.hashCode ^ path.hashCode;
}
