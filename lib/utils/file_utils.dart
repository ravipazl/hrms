// lib/utils/file_utils.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class FileUtils {
  // Supported file types with their MIME types
  static const Map<String, List<String>> supportedFileTypes = {
    'pdf': ['application/pdf'],
    'doc': ['application/msword'],
    'docx': ['application/vnd.openxmlformats-officedocument.wordprocessingml.document'],
    'jpg': ['image/jpeg'],
    'jpeg': ['image/jpeg'],
    'png': ['image/png'],
    'txt': ['text/plain'],
  };

  /// Get file extension without the dot
  static String getFileExtension(String filePath) {
    return path.extension(filePath).toLowerCase().replaceFirst('.', '');
  }

  /// Get file name without path
  static String getFileName(String filePath) {
    return path.basename(filePath);
  }

  /// Get file name without extension
  static String getFileNameWithoutExtension(String filePath) {
    return path.basenameWithoutExtension(filePath);
  }

  /// Check if file type is supported
  static bool isFileTypeSupported(String filePath, List<String> allowedExtensions) {
    final extension = getFileExtension(filePath);
    return allowedExtensions.contains(extension);
  }

  /// Get MIME type for file
  static String? getMimeType(String filePath) {
    final extension = getFileExtension(filePath);
    return supportedFileTypes[extension]?.first;
  }

  /// Validate file size
  static bool isFileSizeValid(File file, int maxSizeInMB) {
    final fileSizeInBytes = file.lengthSync();
    final maxSizeInBytes = maxSizeInMB * 1024 * 1024;
    return fileSizeInBytes <= maxSizeInBytes;
  }

  /// Format file size in human readable format
  static String formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return "${size.toStringAsFixed(size < 10 ? 1 : 0)} ${suffixes[i]}";
  }

  /// Get file type category for UI purposes
  static FileTypeCategory getFileTypeCategory(String filePath) {
    final extension = getFileExtension(filePath);
    switch (extension) {
      case 'pdf':
        return FileTypeCategory.pdf;
      case 'doc':
      case 'docx':
        return FileTypeCategory.document;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return FileTypeCategory.image;
      case 'txt':
        return FileTypeCategory.text;
      default:
        return FileTypeCategory.other;
    }
  }

  /// Validate file for upload
  static FileValidationResult validateFile(
    File file,
    List<String> allowedExtensions,
    int maxSizeInMB,
  ) {
    final fileName = getFileName(file.path);
    
    // Check if file exists
    if (!file.existsSync()) {
      return FileValidationResult(
        isValid: false,
        error: 'File does not exist: $fileName',
      );
    }

    // Check file type
    if (!isFileTypeSupported(file.path, allowedExtensions)) {
      return FileValidationResult(
        isValid: false,
        error: 'File type not allowed for $fileName. Allowed types: ${allowedExtensions.join(', ')}',
      );
    }

    // Check file size
    if (!isFileSizeValid(file, maxSizeInMB)) {
      final fileSize = formatFileSize(file.lengthSync());
      return FileValidationResult(
        isValid: false,
        error: 'File size ($fileSize) exceeds maximum allowed size (${maxSizeInMB}MB) for $fileName',
      );
    }

    return FileValidationResult(isValid: true);
  }

  /// Create a safe file URL for web preview
  static String createFilePreviewUrl(String filePath) {
    // For local files, we can't create direct URLs in Flutter web
    // This would need to be handled by uploading to a server first
    return filePath;
  }

  /// Get appropriate icon for file type
  static String getFileTypeIcon(String filePath) {
    final category = getFileTypeCategory(filePath);
    switch (category) {
      case FileTypeCategory.pdf:
        return '📄';
      case FileTypeCategory.document:
        return '📝';
      case FileTypeCategory.image:
        return '🖼️';
      case FileTypeCategory.text:
        return '📄';
      case FileTypeCategory.other:
        return '📎';
    }
  }
}

/// File type categories for UI handling
enum FileTypeCategory {
  pdf,
  document,
  image,
  text,
  other,
}

/// Result of file validation
class FileValidationResult {
  final bool isValid;
  final String? error;

  FileValidationResult({
    required this.isValid,
    this.error,
  });
}

/// File upload progress callback
typedef FileUploadProgressCallback = void Function(double progress);

/// File upload completion callback
typedef FileUploadCompletionCallback = void Function(bool success, String? error);

/// Enhanced Preview Utilities
class PreviewUtils {
  /// Open document in browser with enhanced viewing options
  static Future<void> openDocumentInBrowser(String url, {String? parameters}) async {
    final fullUrl = parameters != null && parameters.isNotEmpty ? url + parameters : url;
    print('🌐 Opening document in browser: $fullUrl');
    
    if (kIsWeb) {
      html.window.open(fullUrl, '_blank');
    } else {
      final uri = Uri.parse(fullUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch $fullUrl');
      }
    }
  }
  
  /// Open document in Google Docs viewer
  static Future<void> openInGoogleDocsViewer(String url) async {
    final viewerUrl = 'https://docs.google.com/gview?url=${Uri.encodeComponent(url)}&embedded=true';
    print('🗺 Opening in Google Docs viewer: $viewerUrl');
    
    if (kIsWeb) {
      html.window.open(viewerUrl, '_blank');
    } else {
      final uri = Uri.parse(viewerUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch Google Docs viewer');
      }
    }
  }
  
  /// Download document
  static void downloadDocument(String url, String fileName) {
    print('📁 Downloading document: $fileName');
    
    if (kIsWeb) {
      html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
    } else {
      // For mobile platforms, opening the URL will trigger download or view
      openDocumentInBrowser(url);
    }
  }
  
  /// Get optimized URL for document viewing
  static String getOptimizedViewUrl(String url, String extension) {
    final ext = extension.toLowerCase();
    
    switch (ext) {
      case 'pdf':
        return '$url#view=FitH'; // PDF viewer with fit-to-height
      case 'doc':
      case 'docx':
        if (url.contains('127.0.0.1') || url.contains('localhost')) {
          // For localhost, add inline disposition
          return url.contains('?') ? '$url&disposition=inline' : '$url?disposition=inline';
        } else {
          // For public URLs, return as-is (Google Docs viewer will be used separately)
          return url;
        }
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return url; // Images display directly
      default:
        return url.contains('?') ? '$url&view=inline' : '$url?view=inline';
    }
  }
  
  /// Check if file can be previewed inline
  static bool canPreviewInline(String extension) {
    final ext = extension.toLowerCase();
    return ['pdf', 'jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(ext);
  }
  
  /// Get appropriate preview action text
  static String getPreviewActionText(String extension) {
    final ext = extension.toLowerCase();
    
    switch (ext) {
      case 'pdf':
        return 'View PDF';
      case 'doc':
      case 'docx':
        return 'View Document';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return 'View Image';
      default:
        return 'Open File';
    }
  }
  
  /// Extract filename from URL with enhanced fallbacks
  static String extractFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      String fileName = '';
      
      if (uri.pathSegments.isNotEmpty) {
        fileName = Uri.decodeComponent(uri.pathSegments.last);
      } else if (uri.path.isNotEmpty) {
        final pathParts = uri.path.split('/');
        if (pathParts.isNotEmpty) {
          fileName = pathParts.last;
        }
      }
      
      // Remove query parameters
      if (fileName.contains('?')) {
        fileName = fileName.split('?').first;
      }
      
      // If still no proper filename, provide a default based on URL content
      if (fileName.isEmpty || fileName.length < 3) {
        if (url.toLowerCase().contains('pdf')) {
          fileName = 'Document.pdf';
        } else if (url.toLowerCase().contains('doc')) {
          fileName = 'Document.doc';
        } else if (url.toLowerCase().contains('jpg') || url.toLowerCase().contains('jpeg')) {
          fileName = 'Image.jpg';
        } else if (url.toLowerCase().contains('png')) {
          fileName = 'Image.png';
        } else {
          fileName = 'Document';
        }
      }
      
      return fileName;
    } catch (e) {
      // Final fallback
      if (url.contains('/')) {
        final parts = url.split('/');
        if (parts.isNotEmpty && parts.last.isNotEmpty) {
          String fileName = parts.last;
          if (fileName.contains('?')) {
            fileName = fileName.split('?').first;
          }
          return fileName.isNotEmpty ? fileName : 'Document';
        }
      }
      return 'Document';
    }
  }
}
