// lib/widgets/multi_file_upload_widget.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../models/file_preview.dart';

/// Multi-file upload widget supporting multiple document uploads
/// Based on the React multi-file upload implementation
class MultiFileUploadWidget extends StatefulWidget {
  final String? label;
  final String? helpText;
  final bool required;
  final List<FilePreview> initialFiles;
  final Function(List<FilePreview>) onFilesChanged;
  final Function(String?)? onError;
  final List<String> allowedExtensions;
  final int maxFileSizeInMB;
  final bool enabled;
  final int? maxFiles; // Optional max number of files

  const MultiFileUploadWidget({
    super.key,
    this.label,
    this.helpText,
    this.required = false,
    this.initialFiles = const [],
    required this.onFilesChanged,
    this.onError,
    this.allowedExtensions = const ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    this.maxFileSizeInMB = 5,
    this.enabled = true,
    this.maxFiles,
  });

  @override
  State<MultiFileUploadWidget> createState() => _MultiFileUploadWidgetState();
}

class _MultiFileUploadWidgetState extends State<MultiFileUploadWidget> {
  List<FilePreview> _filePreviews = [];
  bool _isHovering = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _filePreviews = List.from(widget.initialFiles);
    print('📎 MultiFileUpload initState:');
    print('   - Initial files count: ${_filePreviews.length}');
  }

  @override
  void didUpdateWidget(MultiFileUploadWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFiles != oldWidget.initialFiles) {
      setState(() {
        _filePreviews = List.from(widget.initialFiles);
      });
      print('🔄 MultiFileUpload - Initial files updated: ${_filePreviews.length}');
    }
  }

  void _setError(String message) {
    setState(() {
      _errorMessage = message;
    });
    widget.onError?.call(message);
    
    // Clear error after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _errorMessage = null;
        });
        widget.onError?.call(null);
      }
    });
  }

  void _clearError() {
    setState(() {
      _errorMessage = null;
    });
    widget.onError?.call(null);
  }

  bool _validatePlatformFile(PlatformFile file) {
    // Check file size
    final maxSizeInBytes = widget.maxFileSizeInMB * 1024 * 1024;
    
    if (file.size > maxSizeInBytes) {
      _setError('File ${file.name} exceeds ${widget.maxFileSizeInMB}MB limit');
      return false;
    }

    // Check file extension
    final extension = _getFileExtension(file.name);
    if (!widget.allowedExtensions.contains(extension.toLowerCase())) {
      _setError('File type not allowed: $extension. Allowed: ${widget.allowedExtensions.join(', ')}');
      return false;
    }

    // Check max files limit
    if (widget.maxFiles != null && _filePreviews.length >= widget.maxFiles!) {
      _setError('Maximum ${widget.maxFiles} files allowed');
      return false;
    }

    return true;
  }

  String _getFileExtension(String fileName) {
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot != -1 && lastDot < fileName.length - 1) {
      return fileName.substring(lastDot + 1);
    }
    return '';
  }

  Future<void> _pickFiles() async {
    if (!widget.enabled) return;
    
    try {
      _clearError();

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: widget.allowedExtensions,
        allowMultiple: true, // ✅ Allow multiple files
        withData: kIsWeb, // Load file data for web
      );

      if (result != null && result.files.isNotEmpty) {
        final validFiles = <FilePreview>[];
        
        for (final platformFile in result.files) {
          if (_validatePlatformFile(platformFile)) {
            final filePreview = FilePreview.fromPlatformFile(platformFile);
            validFiles.add(filePreview);
          }
        }
        
        if (validFiles.isNotEmpty) {
          setState(() {
            _filePreviews.addAll(validFiles);
          });
          
          widget.onFilesChanged(_filePreviews);
          
          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${validFiles.length} file(s) uploaded successfully'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      _setError('Error picking files: $e');
    }
  }

  void _removeFile(int index) {
    if (!widget.enabled) return;
    
    setState(() {
      _filePreviews.removeAt(index);
    });
    widget.onFilesChanged(_filePreviews);
    _clearError();
  }

  void _clearAllFiles() {
    if (!widget.enabled) return;
    
    setState(() {
      _filePreviews.clear();
    });
    widget.onFilesChanged(_filePreviews);
    _clearError();
  }

  IconData _getFileTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'image':
        return Icons.image;
      case 'document':
      default:
        return Icons.description;
    }
  }

  Color _getFileTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Colors.red[600]!;
      case 'image':
        return Colors.green[600]!;
      case 'document':
      default:
        return Colors.blue[600]!;
    }
  }

  Future<void> _previewFile(FilePreview filePreview) async {
    try {
      if (filePreview.url != null && filePreview.url!.isNotEmpty) {
        // Existing file from server
        print('🔗 Opening existing file: ${filePreview.url}');
        
        if (kIsWeb) {
          html.window.open(filePreview.url!, '_blank');
        } else {
          await launchUrl(Uri.parse(filePreview.url!), mode: LaunchMode.externalApplication);
        }
      } else if (kIsWeb && filePreview.platformFile != null && filePreview.platformFile!.bytes != null) {
        // New file on web - create blob URL
        print('🌐 Opening new web file: ${filePreview.name}');
        
        final extension = _getFileExtension(filePreview.name).toLowerCase();
        final mimeType = _getMimeType(extension);
        final blob = html.Blob([filePreview.platformFile!.bytes!], mimeType);
        final url = html.Url.createObjectUrlFromBlob(blob);
        
        html.window.open(url, '_blank');
        
        // Clean up blob URL after delay
        Future.delayed(const Duration(seconds: 60), () {
          html.Url.revokeObjectUrl(url);
        });
      } else if (filePreview.file != null) {
        // Mobile platform
        await launchUrl(Uri.file(filePreview.file!.path), mode: LaunchMode.externalApplication);
      }
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening ${filePreview.name}...'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green[600],
          ),
        );
      }
    } catch (e) {
      _setError('Error previewing file: $e');
    }
  }

  String _getMimeType(String extension) {
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      default:
        return 'application/octet-stream';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Text(
                  widget.label!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                if (widget.required)
                  const Text(
                    ' *',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        
        // Help text
        if (widget.helpText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              widget.helpText!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),

        // Upload area
        MouseRegion(
          onEnter: (_) => setState(() => _isHovering = true),
          onExit: (_) => setState(() => _isHovering = false),
          child: GestureDetector(
            onTap: widget.enabled ? _pickFiles : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _errorMessage != null
                      ? Colors.red
                      : _isHovering
                          ? Colors.blue[400]!
                          : Colors.grey[300]!,
                  width: 2,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(8),
                color: _errorMessage != null
                    ? Colors.red[50]
                    : _isHovering
                        ? Colors.blue[50]
                        : Colors.white,
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 48,
                    color: _isHovering ? Colors.blue[400] : Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Click to upload ${_filePreviews.isEmpty ? '' : 'additional '}documents',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: _isHovering ? Colors.blue[700] : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.allowedExtensions.map((e) => e.toUpperCase()).join(', ')} up to ${widget.maxFileSizeInMB}MB each (Multiple files allowed)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Files list
        if (_filePreviews.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Uploaded Files (${_filePreviews.length})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (widget.enabled)
                TextButton.icon(
                  onPressed: _clearAllFiles,
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Clear All'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          
          // File items
          ..._filePreviews.asMap().entries.map((entry) {
            final index = entry.key;
            final filePreview = entry.value;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: filePreview.isExisting ? Colors.green[50] : Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: filePreview.isExisting ? Colors.green[200]! : Colors.grey[200]!,
                ),
              ),
              child: Row(
                children: [
                  // File icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getFileTypeColor(filePreview.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getFileTypeIcon(filePreview.type),
                      color: _getFileTypeColor(filePreview.type),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // File info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          filePreview.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              filePreview.formattedSize,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (filePreview.isExisting) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '✓ Existing',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green[800],
                                  ),
                                ),
                              ),
                            ],
                            if (filePreview.isNew) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'New Upload',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue[800],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Action buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Preview button
                      IconButton(
                        icon: const Icon(Icons.visibility, size: 20),
                        onPressed: () => _previewFile(filePreview),
                        tooltip: 'Preview',
                        color: Colors.blue[600],
                      ),
                      
                      // Remove button
                      if (widget.enabled)
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          onPressed: () => _removeFile(index),
                          tooltip: 'Remove',
                          color: Colors.red[600],
                        ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],

        // Error message
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Row(
              children: [
                Icon(Icons.error, color: Colors.red[600], size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.red[600],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
