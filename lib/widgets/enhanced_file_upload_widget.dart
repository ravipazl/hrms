// lib/widgets/enhanced_file_upload_widget.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class EnhancedFileUploadWidget extends StatefulWidget {
  final String? label;
  final String? helpText;
  final bool required;
  final File? initialFile;
  final String? initialFileUrl;
  final Function(File?) onFileChanged;
  final Function(PlatformFile?)? onPlatformFileChanged; // For web compatibility
  final Function(String?)? onError;
  final List<String> allowedExtensions;
  final int maxFileSizeInMB;
  final bool showPreview;
  final bool enabled;
  
  // PREVIEW CONFIGURATION: Set this to control preview behavior
  final bool useDirectPreview; // true = direct open, false = modal preview

  const EnhancedFileUploadWidget({
    super.key,
    this.label,
    this.helpText,
    this.required = false,
    this.initialFile,
    this.initialFileUrl,
    required this.onFileChanged,
    this.onPlatformFileChanged,
    this.onError,
    this.allowedExtensions = const ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    this.maxFileSizeInMB = 5,
    this.showPreview = true,
    this.enabled = true,
    this.useDirectPreview = true, // DEFAULT: Direct preview (opens document immediately)
  });

  @override
  State<EnhancedFileUploadWidget> createState() => _EnhancedFileUploadWidgetState();
}

class _EnhancedFileUploadWidgetState extends State<EnhancedFileUploadWidget>
    with SingleTickerProviderStateMixin {
  File? _selectedFile;
  PlatformFile? _selectedPlatformFile; // For web compatibility
  String? _existingFileUrl;
  bool _isHovering = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _selectedFile = widget.initialFile;
    _existingFileUrl = widget.initialFileUrl;
    
    // Debug logging for file upload widget initialization
    print('📎 FileUploadWidget initState:');
    print('   - Initial File: $_selectedFile');
    print('   - Initial File URL: $_existingFileUrl');
    print('   - Widget Initial File: ${widget.initialFile}');
    print('   - Widget Initial File URL: ${widget.initialFileUrl}');
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(EnhancedFileUploadWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFile != oldWidget.initialFile) {
      print('🔄 FileUploadWidget - Initial file changed: ${widget.initialFile}');
      setState(() {
        _selectedFile = widget.initialFile;
      });
    }
    if (widget.initialFileUrl != oldWidget.initialFileUrl) {
      print('🔄 FileUploadWidget - Initial file URL changed: ${widget.initialFileUrl}');
      setState(() {
        _existingFileUrl = widget.initialFileUrl;
      });
    }
  }

  IconData _getFileTypeIcon(String fileName) {
    final extension = _getFileExtension(fileName);
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileTypeColor(String fileName) {
    final extension = _getFileExtension(fileName);
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Colors.red[600]!;
      case 'doc':
      case 'docx':
        return Colors.blue[600]!;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Colors.green[600]!;
      case 'txt':
        return Colors.grey[600]!;
      default:
        return Colors.orange[600]!;
    }
  }

  String _getFileExtension(String fileName) {
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot != -1 && lastDot < fileName.length - 1) {
      return fileName.substring(lastDot + 1);
    }
    return '';
  }

  String _formatFileSize(int bytes) {
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

  bool _validatePlatformFile(PlatformFile file) {
    // Check file size
    final maxSizeInBytes = widget.maxFileSizeInMB * 1024 * 1024;
    
    if (file.size > maxSizeInBytes) {
      _setError('File size (${_formatFileSize(file.size)}) exceeds maximum allowed size (${widget.maxFileSizeInMB}MB)');
      return false;
    }

    // Check file extension
    final extension = _getFileExtension(file.name);
    if (!widget.allowedExtensions.contains(extension.toLowerCase())) {
      _setError('File type not allowed. Allowed types: ${widget.allowedExtensions.join(', ')}');
      return false;
    }

    return true;
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

  Future<void> _pickFile() async {
    if (!widget.enabled) return;
    
    try {
      _clearError();
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: widget.allowedExtensions,
        allowMultiple: false,
        withData: kIsWeb, // Load file data for web
      );

      if (result != null && result.files.isNotEmpty) {
        final platformFile = result.files.first;
        
        if (_validatePlatformFile(platformFile)) {
          // Simulate upload progress
          for (int i = 0; i <= 100; i += 10) {
            await Future.delayed(const Duration(milliseconds: 50));
            if (mounted) {
              setState(() {
                _uploadProgress = i / 100;
              });
            }
          }
          
          setState(() {
            _selectedPlatformFile = platformFile;
            _existingFileUrl = null; // Clear existing file when new file is selected
            _isUploading = false;
            
            // For mobile platforms, also set the File object
            if (!kIsWeb && platformFile.path != null) {
              _selectedFile = File(platformFile.path!);
            } else {
              _selectedFile = null;
            }
          });
          
          // Call the appropriate callback
          if (kIsWeb) {
            widget.onPlatformFileChanged?.call(_selectedPlatformFile);
          } else {
            widget.onFileChanged(_selectedFile);
          }
        } else {
          setState(() {
            _isUploading = false;
          });
        }
      } else {
        setState(() {
          _isUploading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      _setError('Error picking file: $e');
    }
  }

  void _removeFile() {
    if (!widget.enabled) return;
    
    setState(() {
      _selectedFile = null;
      _selectedPlatformFile = null;
      _existingFileUrl = null;
    });
    widget.onFileChanged(null);
    widget.onPlatformFileChanged?.call(null);
    _clearError();
  }

  Future<void> _previewFile(String fileName, [String? url]) async {
    print('👁️\n=== CONFIGURABLE DOCUMENT PREVIEW ===');
    print('📎 Preview requested for: "$fileName"');
    print('🔗 URL provided: ${url ?? 'NULL'}');
    print('⚙️ Preview mode: ${widget.useDirectPreview ? 'DIRECT' : 'MODAL'}');
    print('📱 Platform info:');
    print('   - Has selected platform file: ${_selectedPlatformFile != null}');
    print('   - Has selected regular file: ${_selectedFile != null}');
    print('   - Is web platform: $kIsWeb');
    print('   - Existing file URL: $_existingFileUrl');
    
    try {
      if (widget.useDirectPreview) {
        // DIRECT PREVIEW MODE: Open document immediately
        await _handleDirectPreview(fileName, url);
      } else {
        // MODAL PREVIEW MODE: Show enhanced preview dialog first
        await _handleModalPreview(fileName, url);
      }
    } catch (e) {
      print('❌ Error in preview: $e');
      _setError('Error opening document: $e');
    }
    
    print('=== END CONFIGURABLE PREVIEW ===\n');
  }

  /// Handle direct preview (opens document immediately)
  Future<void> _handleDirectPreview(String fileName, String? url) async {
    if (url != null && url.isNotEmpty) {
      print('✅ Valid URL found - opening document directly');
      
      // Get file extension to determine best viewing method
      final extension = _getFileExtension(fileName).toLowerCase();
      print('📄 File extension detected: $extension');
      
      String viewUrl;
      
      if (['pdf'].contains(extension)) {
        // For PDF: Use viewer-friendly URL that displays instead of downloads
        viewUrl = '$url#view=FitH';
        print('📜 PDF: Using viewer URL: $viewUrl');
      } else if (['doc', 'docx'].contains(extension)) {
        // For DOC/DOCX: Check if URL is localhost (Google Docs viewer won't work)
        if (url.contains('127.0.0.1') || url.contains('localhost')) {
          // For localhost, try multiple approaches for better viewing
          // Approach 1: Add inline content-disposition parameter
          if (url.contains('?')) {
            viewUrl = '$url&disposition=inline';
          } else {
            viewUrl = '$url?disposition=inline';
          }
          print('📝 DOC (localhost): Opening with inline parameter: $viewUrl');
        } else {
          // For public URLs, use Google Docs viewer
          viewUrl = 'https://docs.google.com/gview?url=${Uri.encodeComponent(url)}&embedded=true';
          print('📝 DOC (public): Using Google Docs viewer: $viewUrl');
        }
      } else if (['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(extension)) {
        // For images: Display directly
        viewUrl = url;
        print('🖼️ IMAGE: Displaying directly: $viewUrl');
      } else {
        // For other files: Try to display with view parameter
        viewUrl = '$url?view=inline';
        print('📁 OTHER: Using inline view: $viewUrl');
      }
      
      // Open in new tab with view-friendly URL
      if (kIsWeb) {
        print('🌐 Opening document directly in browser tab...');
        html.window.open(viewUrl, '_blank');
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening $fileName in new tab...'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green[600],
            ),
          );
        }
      } else {
        print('📱 Opening document in app browser...');
        launchUrl(Uri.parse(viewUrl), mode: LaunchMode.inAppBrowserView);
      }
      
    } else if (kIsWeb && _selectedPlatformFile != null) {
      print('✅ Web platform with new file - opening directly in new tab');
      // For web platform with selected file - open in new tab directly
      _openFileInNewTabDirect();
    } else {
      print('❌ No valid URL or file available for preview');
      _setError('No document available for preview');
    }
  }

  /// Handle modal preview (shows enhanced preview dialog first)
  Future<void> _handleModalPreview(String fileName, String? url) async {
    if (url != null && url.isNotEmpty) {
      print('✅ Valid URL found - showing enhanced preview modal');
      await _showEnhancedPreviewDialog(fileName, url);
    } else if (kIsWeb && _selectedPlatformFile != null) {
      print('✅ Web platform with new file - showing enhanced preview modal');
      await _showNewFilePreviewDialog();
    } else {
      print('❌ No valid URL or file available for preview');
      _setError('No document available for preview');
    }
  }

  /// Enhanced preview dialog with better controls and error handling
  Future<void> _showEnhancedPreviewDialog(String fileName, String url) async {
    // Enhanced filename extraction
    String displayFileName = _extractEnhancedFileName(fileName, url);
    String actualExtension = _getFileExtension(displayFileName);
    
    print('🔍 Enhanced preview dialog info:');
    print('   - Display fileName: "$displayFileName"');
    print('   - Extension: "$actualExtension"');
    print('   - Original URL: "$url"');
    
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                // Enhanced Header
                _buildEnhancedPreviewHeader(displayFileName, actualExtension, url),
                
                // Enhanced Preview Content
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _buildEnhancedPreviewContent(displayFileName, actualExtension, url),
                  ),
                ),
                
                // Enhanced Footer with multiple action buttons
                _buildEnhancedPreviewFooter(displayFileName, actualExtension, url),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Enhanced filename extraction with better fallbacks
  String _extractEnhancedFileName(String fileName, String url) {
    String displayFileName = fileName;
    
    // If fileName is generic or too short, extract from URL
    if (fileName == 'Existing file' || fileName.trim().isEmpty || fileName.length < 3) {
      try {
        final uri = Uri.parse(url);
        if (uri.pathSegments.isNotEmpty) {
          displayFileName = Uri.decodeComponent(uri.pathSegments.last);
        } else {
          final pathParts = uri.path.split('/');
          if (pathParts.isNotEmpty && pathParts.last.isNotEmpty) {
            displayFileName = pathParts.last;
          }
        }
        
        // Remove query parameters
        if (displayFileName.contains('?')) {
          displayFileName = displayFileName.split('?').first;
        }
      } catch (e) {
        // Fallback extraction
        if (url.contains('/')) {
          final parts = url.split('/');
          if (parts.isNotEmpty && parts.last.isNotEmpty) {
            displayFileName = parts.last.split('?').first;
          }
        }
      }
    }
    
    // Final fallback with file type detection
    if (displayFileName.isEmpty || displayFileName.length < 3) {
      if (url.toLowerCase().contains('pdf')) {
        displayFileName = 'Job Description.pdf';
      } else if (url.toLowerCase().contains('doc')) {
        displayFileName = 'Job Description.doc';
      } else if (url.toLowerCase().contains('jpg') || url.toLowerCase().contains('jpeg')) {
        displayFileName = 'Job Description.jpg';
      } else if (url.toLowerCase().contains('png')) {
        displayFileName = 'Job Description.png';
      } else {
        displayFileName = 'Job Description Document';
      }
    }
    
    return displayFileName;
  }

  /// Enhanced preview header with better file info display
  Widget _buildEnhancedPreviewHeader(String fileName, String extension, String url) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          // File type icon with enhanced styling
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getFileTypeColor(fileName).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getFileTypeIcon(fileName),
              color: _getFileTypeColor(fileName),
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          
          // File information
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Document Preview',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  fileName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (extension.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getFileTypeColor(fileName).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      extension.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _getFileTypeColor(fileName),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Close button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            tooltip: 'Close Preview',
          ),
        ],
      ),
    );
  }

  /// Enhanced preview content with better error handling and loading states
  Widget _buildEnhancedPreviewContent(String fileName, String extension, String url) {
    final ext = extension.toLowerCase();
    
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(ext)) {
      return _buildEnhancedImagePreview(url, fileName);
    } else if (ext == 'pdf') {
      return _buildEnhancedPdfPreview(url, fileName);
    } else if (['doc', 'docx'].contains(ext)) {
      return _buildEnhancedDocumentPreview(url, fileName);
    } else {
      return _buildEnhancedGenericPreview(fileName, extension, url);
    }
  }

  /// Enhanced image preview with loading and error states
  Widget _buildEnhancedImagePreview(String url, String fileName) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey[100],
        child: Image.network(
          url,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                  const SizedBox(height: 16),
                  const Text('Loading image...'),
                  if (loadingProgress.expectedTotalBytes != null)
                    Text(
                      '${(loadingProgress.cumulativeBytesLoaded / 1024).toStringAsFixed(1)} KB of '
                      '${(loadingProgress.expectedTotalBytes! / 1024).toStringAsFixed(1)} KB',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.red[50],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[600], size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'Unable to load image',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'The image may be corrupted or inaccessible',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (kIsWeb) {
                          html.window.open(url, '_blank');
                        } else {
                          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open in Browser'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Enhanced PDF preview with multiple viewing options
  Widget _buildEnhancedPdfPreview(String url, String fileName) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.red[50]!, Colors.red[100]!],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf, color: Colors.red[600], size: 80),
            const SizedBox(height: 24),
            const Text(
              'PDF Document Preview',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              fileName,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Multiple action buttons for PDF
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _openDocumentInBrowser(url, '#view=FitH'),
                  icon: const Icon(Icons.visibility),
                  label: const Text('View PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _openDocumentInBrowser(url),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open in New Tab'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                if (kIsWeb)
                  ElevatedButton.icon(
                    onPressed: () => _downloadDocument(url, fileName),
                    icon: const Icon(Icons.download),
                    label: const Text('Download'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'PDF documents will open in your browser\'s built-in viewer for the best experience.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Enhanced document preview for DOC/DOCX files
  Widget _buildEnhancedDocumentPreview(String url, String fileName) {
    final isLocalhost = url.contains('127.0.0.1') || url.contains('localhost');
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue[50]!, Colors.blue[100]!],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description, color: Colors.blue[600], size: 80),
            const SizedBox(height: 24),
            const Text(
              'Document Preview',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              fileName,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Multiple action buttons for documents
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _openDocumentInBrowser(url, isLocalhost ? '?disposition=inline' : ''),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open Document'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                if (!isLocalhost)
                  ElevatedButton.icon(
                    onPressed: () => _openInGoogleDocsViewer(url),
                    icon: const Icon(Icons.visibility),
                    label: const Text('Preview'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                if (kIsWeb)
                  ElevatedButton.icon(
                    onPressed: () => _downloadDocument(url, fileName),
                    icon: const Icon(Icons.download),
                    label: const Text('Download'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isLocalhost
                    ? 'Local documents will open in your browser. Use download if viewing is not available.'
                    : 'Documents can be previewed online or downloaded for offline viewing.',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Enhanced generic preview for other file types
  Widget _buildEnhancedGenericPreview(String fileName, String extension, String url) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.orange[50]!, Colors.orange[100]!],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getFileTypeIcon(fileName),
              color: _getFileTypeColor(fileName),
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              '${extension.toUpperCase()} Document',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              fileName,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            ElevatedButton.icon(
              onPressed: () => _openDocumentInBrowser(url),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open Document'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getFileTypeColor(fileName),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'This file type will open in your default application or browser.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Enhanced preview footer with action buttons
  Widget _buildEnhancedPreviewFooter(String fileName, String extension, String url) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'File: ${fileName.length > 30 ? '${fileName.substring(0, 30)}...' : fileName}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'URL: ${url.length > 40 ? '${url.substring(0, 40)}...' : url}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          
          // Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _openDocumentInBrowser(url);
                },
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Open in Browser'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// New file preview dialog for newly uploaded files
  Future<void> _showNewFilePreviewDialog() async {
    if (_selectedPlatformFile == null) return;
    
    final fileName = _selectedPlatformFile!.name;
    final extension = _getFileExtension(fileName);
    
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getFileTypeIcon(fileName),
                        color: _getFileTypeColor(fileName),
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'New File Preview',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              fileName,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _buildNewFilePreviewContent(fileName, extension),
                  ),
                ),
                
                // Footer
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _openFileInNewTab();
                        },
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Open in New Tab'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Content for newly uploaded file preview
  Widget _buildNewFilePreviewContent(String fileName, String extension) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getFileTypeIcon(fileName),
            color: _getFileTypeColor(fileName),
            size: 80,
          ),
          const SizedBox(height: 24),
          Text(
            'New ${extension.toUpperCase()} File',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            fileName,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'File size: ${_formatFileSize(_selectedPlatformFile!.size)}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Click "Open in New Tab" to preview this file in your browser.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Helper method to open document in browser with optional parameters
  void _openDocumentInBrowser(String url, [String parameters = '']) {
    final fullUrl = parameters.isNotEmpty ? url + parameters : url;
    print('🌐 Opening document in browser: $fullUrl');
    
    if (kIsWeb) {
      html.window.open(fullUrl, '_blank');
    } else {
      launchUrl(Uri.parse(fullUrl), mode: LaunchMode.externalApplication);
    }
  }

  /// Helper method to open in Google Docs viewer
  void _openInGoogleDocsViewer(String url) {
    final viewerUrl = 'https://docs.google.com/gview?url=${Uri.encodeComponent(url)}&embedded=true';
    print('🗺 Opening in Google Docs viewer: $viewerUrl');
    
    if (kIsWeb) {
      html.window.open(viewerUrl, '_blank');
    } else {
      launchUrl(Uri.parse(viewerUrl), mode: LaunchMode.externalApplication);
    }
  }

  /// Helper method to download document
  void _downloadDocument(String url, String fileName) {
    print('📁 Downloading document: $fileName');
    
    if (kIsWeb) {
      html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
    } else {
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  /// Legacy preview dialog - kept for backward compatibility
  void _showPreviewDialog(String fileName, String url) {
    // ENHANCED: Extract better file information from URL if fileName is not descriptive
    String displayFileName = fileName;
    String actualExtension = '';
    
    // Debug logging to understand the data
    print('🔍 Preview dialog debug info:');
    print('   - Original fileName: "$fileName"');
    print('   - URL: "$url"');
    print('   - fileName length: ${fileName.length}');
    print('   - fileName == "Existing file": ${fileName == "Existing file"}');
    
    // If fileName is just 'Existing file' or similar, extract from URL
    if (fileName == 'Existing file' || fileName.trim().isEmpty || fileName.length < 3) {
      try {
        final uri = Uri.parse(url);
        print('   - Parsed URI: $uri');
        print('   - Path segments: ${uri.pathSegments}');
        print('   - Last path segment: ${uri.pathSegments.isNotEmpty ? uri.pathSegments.last : "none"}');
        
        if (uri.pathSegments.isNotEmpty) {
          displayFileName = uri.pathSegments.last;
          // Remove URL encoding if present
          displayFileName = Uri.decodeComponent(displayFileName);
        } else {
          // Try to extract from the full path
          final path = uri.path;
          if (path.contains('/')) {
            displayFileName = path.split('/').last;
          } else {
            displayFileName = 'Uploaded Document';
          }
        }
      } catch (e) {
        print('   - Error parsing URL: $e');
        // Try simple string extraction as fallback
        if (url.contains('/')) {
          final parts = url.split('/');
          if (parts.isNotEmpty) {
            displayFileName = parts.last;
            // Remove query parameters if present
            if (displayFileName.contains('?')) {
              displayFileName = displayFileName.split('?').first;
            }
          }
        }
        
        if (displayFileName.isEmpty || displayFileName.length < 3) {
          displayFileName = 'Uploaded Document';
        }
      }
    }
    
    actualExtension = _getFileExtension(displayFileName);
    
    // If still no extension, try to detect from URL or default to common types
    if (actualExtension.isEmpty) {
      if (url.toLowerCase().contains('pdf')) {
        actualExtension = 'pdf';
        displayFileName = displayFileName.isEmpty ? 'Document.pdf' : '$displayFileName.pdf';
      } else if (url.toLowerCase().contains('doc')) {
        actualExtension = 'doc';
        displayFileName = displayFileName.isEmpty ? 'Document.doc' : '$displayFileName.doc';
      } else {
        actualExtension = 'doc'; // Default assumption for job descriptions
        displayFileName = displayFileName.isEmpty ? 'Job Description Document' : displayFileName;
      }
    }
    
    // Final debug logging
    print('✅ Final preview dialog values:');
    print('   - Display fileName: "$displayFileName"');
    print('   - Extension: "$actualExtension"');
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                _getFileTypeIcon(displayFileName),
                color: _getFileTypeColor(displayFileName),
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Preview Document',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxHeight: 600, minHeight: 450),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // File information
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'File Type: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            actualExtension.isNotEmpty 
                                ? actualExtension.toUpperCase()
                                : 'Document',
                            style: TextStyle(
                              color: _getFileTypeColor(displayFileName),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text(
                            'File: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Expanded(
                            child: Text(
                              displayFileName.isNotEmpty ? displayFileName : 'Job Description Document',
                              style: const TextStyle(color: Colors.black87),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Preview area based on file type
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _buildPreviewContent(displayFileName, actualExtension, url),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            // Open in new tab button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                print('🔗 Opening document in new tab: $url');
                if (kIsWeb) {
                  html.window.open(url, '_blank');
                } else {
                  launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);
                }
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open in New Tab'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
            // Close button
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildPreviewContent(String fileName, String extension, String url) {
    if (['jpg', 'jpeg', 'png'].contains(extension.toLowerCase())) {
      // Image preview - Load and display the actual image
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading image...'),
                ],
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print('❌ Image load error: $error');
            print('🔗 Attempted URL: $url');
            return Container(
              color: Colors.grey[100],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 8),
                    const Text('Unable to load image'),
                    const SizedBox(height: 4),
                    Text(
                      'URL: ${url.length > 50 ? '${url.substring(0, 50)}...' : url}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'The image may be corrupted or inaccessible',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    } else if (extension.toLowerCase() == 'pdf') {
      // PDF preview - Embed PDF viewer
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: kIsWeb
              ? _buildWebPdfViewer(url)
              : _buildNativePdfPreview(url),
        ),
      );
    } else if (['doc', 'docx'].contains(extension.toLowerCase())) {
      // DOC/DOCX preview - Try to use Google Docs viewer
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _buildDocumentViewer(url),
        ),
      );
    } else {
      // Other document types - Show preview info
      return Container(
        color: Colors.blue[50],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getFileTypeIcon(fileName),
                color: _getFileTypeColor(fileName),
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                '${extension.toUpperCase()} Document',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Click "Open in New Tab" to view the document',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Document will open in ${kIsWeb ? 'new browser tab' : 'app browser'}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
  
  // ENHANCED: Web PDF viewer - simple and reliable approach
  Widget _buildWebPdfViewer(String url) {
    if (!kIsWeb) {
      return _buildNativePdfPreview(url);
    }
    
    // For web, show a preview area with direct PDF access
    return Container(
      width: double.infinity,
      height: 400,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.red[50],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.picture_as_pdf, color: Colors.red[600], size: 80),
          const SizedBox(height: 16),
          const Text(
            'PDF Document Preview',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Document is ready to view',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  print('📝 Opening PDF in new tab: $url');
                  html.window.open(url, '_blank');
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  print('📁 Downloading PDF: $url');
                  html.AnchorElement(href: url)
                    ..setAttribute('download', '')
                    ..click();
                },
                icon: const Icon(Icons.download),
                label: const Text('Download'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'URL: ${url.length > 60 ? '${url.substring(0, 60)}...' : url}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  // Remove the complex _createWebPdfFrame method - not needed anymore
  
  // ENHANCED: Native PDF preview fallback
  Widget _buildNativePdfPreview(String url) {
    return Container(
      color: Colors.red[50],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf, color: Colors.red, size: 64),
            SizedBox(height: 16),
            Text(
              'PDF Document',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Click "Open in New Tab" to view the PDF document',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'PDFs will open in your browser\'s built-in viewer',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // ENHANCED: Document viewer - simple and reliable approach
  Widget _buildDocumentViewer(String url) {
    if (!kIsWeb) {
      return _buildNativeDocumentPreview(url);
    }
    
    // For web, show a preview area with document access options
    return Container(
      width: double.infinity,
      height: 400,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.blue[50],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description, color: Colors.blue[600], size: 80),
          const SizedBox(height: 16),
          const Text(
            'Document Preview',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'DOC/DOCX document is ready to view',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  print('📝 Opening document in new tab: $url');
                  html.window.open(url, '_blank');
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open Document'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  // Try Google Docs viewer for better preview
                  final viewerUrl = 'https://docs.google.com/gview?url=${Uri.encodeComponent(url)}&embedded=true';
                  print('🗺 Opening in Google Docs viewer: $viewerUrl');
                  html.window.open(viewerUrl, '_blank');
                },
                icon: const Icon(Icons.visibility),
                label: const Text('Preview'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  print('📁 Downloading document: $url');
                  html.AnchorElement(href: url)
                    ..setAttribute('download', '')
                    ..click();
                },
                icon: const Icon(Icons.download),
                label: const Text('Download'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'URL: ${url.length > 60 ? '${url.substring(0, 60)}...' : url}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  // ENHANCED: Native document preview fallback
  Widget _buildNativeDocumentPreview(String url) {
    return Container(
      color: Colors.blue[50],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description, color: Colors.blue, size: 64),
            SizedBox(height: 16),
            Text(
              'Document File',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Click "Open in New Tab" to view the document',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Document will open in your default application',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFileInNewTabDirect() {
    if (!kIsWeb || _selectedPlatformFile?.bytes == null) return;

    final extension = _getFileExtension(_selectedPlatformFile!.name).toLowerCase();
    final fileName = _selectedPlatformFile!.name;
    print('📄 Opening newly uploaded file directly: $fileName');
    print('📄 File extension: $extension');
    
    try {
      if (extension == 'pdf') {
        // Create blob URL for PDF and open for viewing (not download)
        final blob = html.Blob([_selectedPlatformFile!.bytes!], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        
        // Open with view parameters for PDF display
        final viewUrl = '$url#view=FitH';
        print('📜 PDF: Opening with viewer URL: $viewUrl');
        html.window.open(viewUrl, '_blank');
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening $fileName in new tab...'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green[600],
            ),
          );
        }
        
        // Clean up the blob URL after some time
        Future.delayed(const Duration(seconds: 60), () {
          html.Url.revokeObjectUrl(url);
        });
      } else if (['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(extension)) {
        // Create blob URL for images and open for viewing
        final mimeType = extension == 'png' ? 'image/png' : 
                        extension == 'gif' ? 'image/gif' : 'image/jpeg';
        final blob = html.Blob([_selectedPlatformFile!.bytes!], mimeType);
        final url = html.Url.createObjectUrlFromBlob(blob);
        
        print('🖼️ IMAGE: Opening for viewing: $url');
        html.window.open(url, '_blank');
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening $fileName in new tab...'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green[600],
            ),
          );
        }
        
        // Clean up the blob URL after some time
        Future.delayed(const Duration(seconds: 60), () {
          html.Url.revokeObjectUrl(url);
        });
      } else if (['doc', 'docx'].contains(extension)) {
        // For DOC/DOCX, we need to create a temporary URL and use Google Docs viewer
        final mimeType = extension == 'doc' ? 'application/msword' : 
                        'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
        final blob = html.Blob([_selectedPlatformFile!.bytes!], mimeType);
        final url = html.Url.createObjectUrlFromBlob(blob);
        
        // Since Google Docs viewer needs a public URL, we'll open the file directly
        // The browser will try to display it or offer appropriate viewing options
        print('📝 DOC: Opening for viewing: $url');
        html.window.open(url, '_blank');
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening $fileName in new tab...'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green[600],
            ),
          );
        }
        
        // Clean up the blob URL after some time
        Future.delayed(const Duration(seconds: 60), () {
          html.Url.revokeObjectUrl(url);
        });
      } else {
        // For other file types, create blob URL and try to display
        final blob = html.Blob([_selectedPlatformFile!.bytes!]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        
        print('📁 OTHER: Opening for viewing: $url');
        html.window.open(url, '_blank');
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening $fileName in new tab...'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green[600],
            ),
          );
        }
        
        // Clean up the blob URL after some time
        Future.delayed(const Duration(seconds: 60), () {
          html.Url.revokeObjectUrl(url);
        });
      }
    } catch (e) {
      print('❌ Error opening newly uploaded file for viewing: $e');
      _setError('Error opening file for viewing: $e');
    }
  }

  /// Show enhanced preview dialog (alternative method if needed)
  void _showEnhancedPreviewIfNeeded(String fileName, [String? url]) async {
    // This method can be used if you want to show the enhanced preview dialog instead
    // Just call this method instead of _previewFile for the enhanced modal experience
    if (url != null && url.isNotEmpty) {
      await _showEnhancedPreviewDialog(fileName, url);
    } else if (kIsWeb && _selectedPlatformFile != null) {
      await _showNewFilePreviewDialog();
    } else {
      _setError('No document available for preview');
    }
  }

  void _openFileInNewTab() {
    if (!kIsWeb || _selectedPlatformFile?.bytes == null) return;

    final extension = _getFileExtension(_selectedPlatformFile!.name).toLowerCase();
    print('📄 Opening newly uploaded file: ${_selectedPlatformFile!.name}');
    print('📄 File extension: $extension');
    
    try {
      if (extension == 'pdf') {
        // Create blob URL for PDF and open for viewing (not download)
        final blob = html.Blob([_selectedPlatformFile!.bytes!], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        
        // Open with view parameters for PDF display
        final viewUrl = '$url#view=FitH';
        print('📜 PDF: Opening with viewer URL: $viewUrl');
        html.window.open(viewUrl, '_blank');
        
        // Clean up the blob URL after some time
        Future.delayed(const Duration(seconds: 60), () {
          html.Url.revokeObjectUrl(url);
        });
      } else if (['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(extension)) {
        // Create blob URL for images and open for viewing
        final mimeType = extension == 'png' ? 'image/png' : 
                        extension == 'gif' ? 'image/gif' : 'image/jpeg';
        final blob = html.Blob([_selectedPlatformFile!.bytes!], mimeType);
        final url = html.Url.createObjectUrlFromBlob(blob);
        
        print('🖼️ IMAGE: Opening for viewing: $url');
        html.window.open(url, '_blank');
        
        // Clean up the blob URL after some time
        Future.delayed(const Duration(seconds: 60), () {
          html.Url.revokeObjectUrl(url);
        });
      } else if (['doc', 'docx'].contains(extension)) {
        // For DOC/DOCX, we need to create a temporary URL and use Google Docs viewer
        final mimeType = extension == 'doc' ? 'application/msword' : 
                        'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
        final blob = html.Blob([_selectedPlatformFile!.bytes!], mimeType);
        final url = html.Url.createObjectUrlFromBlob(blob);
        
        // Since Google Docs viewer needs a public URL, we'll open the file directly
        // The browser will try to display it or offer appropriate viewing options
        print('📝 DOC: Opening for viewing: $url');
        html.window.open(url, '_blank');
        
        // Clean up the blob URL after some time
        Future.delayed(const Duration(seconds: 60), () {
          html.Url.revokeObjectUrl(url);
        });
      } else {
        // For other file types, create blob URL and try to display
        final blob = html.Blob([_selectedPlatformFile!.bytes!]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        
        print('📁 OTHER: Opening for viewing: $url');
        html.window.open(url, '_blank');
        
        // Clean up the blob URL after some time
        Future.delayed(const Duration(seconds: 60), () {
          html.Url.revokeObjectUrl(url);
        });
      }
    } catch (e) {
      print('❌ Error opening newly uploaded file for viewing: $e');
      _setError('Error opening file for viewing: $e');
    }
  }

  void _showFileInfoDialog(String fileName) {
    final extension = _getFileExtension(fileName);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                _getFileTypeIcon(fileName),
                color: _getFileTypeColor(fileName),
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  fileName,
                  style: const TextStyle(fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('File Type: ${extension.toUpperCase()}'),
              const SizedBox(height: 8),
              if (_selectedPlatformFile != null)
                Text('Size: ${_formatFileSize(_selectedPlatformFile!.size)}')
              else if (_selectedFile != null)
                Text('Size: ${_formatFileSize(_selectedFile!.lengthSync())}'),
              const SizedBox(height: 16),
              if (kIsWeb && ['pdf', 'jpg', 'jpeg', 'png'].contains(extension.toLowerCase()))
                const Text('Click "Open in New Tab" to view the full document.')
              else if (['pdf', 'jpg', 'jpeg', 'png'].contains(extension.toLowerCase()))
                const Text('This file can be opened with your default application.')
              else
                const Text('Preview not available for this file type.'),
            ],
          ),
          actions: [
            if (kIsWeb && ['pdf', 'jpg', 'jpeg', 'png'].contains(extension.toLowerCase()))
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _openFileInNewTab();
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open in New Tab'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                ),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasFile = _selectedFile != null || _selectedPlatformFile != null || _existingFileUrl != null;

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
        ScaleTransition(
          scale: _scaleAnimation,
          child: MouseRegion(
            onEnter: (_) {
              setState(() => _isHovering = true);
              _animationController.forward();
            },
            onExit: (_) {
              setState(() => _isHovering = false);
              _animationController.reverse();
            },
            child: GestureDetector(
              onTap: hasFile ? null : _pickFile,
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
                          : hasFile
                              ? Colors.grey[50]
                              : Colors.white,
                ),
                child: hasFile ? _buildFilePreview() : _buildUploadPrompt(),
              ),
            ),
          ),
        ),

        // Error message
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
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

        // Upload progress
        if (_isUploading)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Uploading... ${(_uploadProgress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _uploadProgress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildUploadPrompt() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.cloud_upload_outlined,
          size: 48,
          color: _isHovering ? Colors.blue[400] : Colors.grey[400],
        ),
        const SizedBox(height: 16),
        Text(
          'Click to upload job description document',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: _isHovering ? Colors.blue[700] : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${widget.allowedExtensions.map((e) => e.toUpperCase()).join(', ')} up to ${widget.maxFileSizeInMB}MB',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        if (widget.enabled) ...[
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.folder_open),
            label: const Text('Choose File'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFilePreview() {
    String fileName;
    int? fileSize;
    bool isExistingFile = false;

    if (_selectedPlatformFile != null) {
      fileName = _selectedPlatformFile!.name;
      fileSize = _selectedPlatformFile!.size;
    } else if (_selectedFile != null) {
      fileName = _selectedFile!.path.split('/').last;
      fileSize = _selectedFile!.lengthSync();
    } else if (_existingFileUrl != null) {
      // ENHANCED: Better filename extraction from existing URL
      fileName = _extractFileNameFromUrl(_existingFileUrl!);
      isExistingFile = true;
    } else {
      fileName = 'Unknown file';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // File icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getFileTypeColor(fileName).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getFileTypeIcon(fileName),
              color: _getFileTypeColor(fileName),
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
                  fileName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  isExistingFile 
                      ? 'Existing file'
                      : fileSize != null 
                          ? _formatFileSize(fileSize)
                          : 'Size unknown',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Preview button
              if (widget.showPreview)
                IconButton(
                  icon: const Icon(Icons.visibility),
                  onPressed: () {
                    print('🔍 Preview button clicked:');
                    print('   - fileName: "$fileName"');
                    print('   - _existingFileUrl: "$_existingFileUrl"');
                    print('   - isExistingFile: $isExistingFile');
                    
                    // Show immediate feedback
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Opening $fileName for preview...'),
                        duration: const Duration(seconds: 2),
                        backgroundColor: Colors.green[600],
                      ),
                    );
                    
                    _previewFile(
                      fileName,
                      _existingFileUrl,
                    );
                  },
                  tooltip: 'Preview',
                  iconSize: 20,
                ),
              
              // Replace button
              if (widget.enabled)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _pickFile,
                  tooltip: 'Replace',
                  iconSize: 20,
                ),
              
              // Remove button
              if (widget.enabled)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: _removeFile,
                  tooltip: 'Remove',
                  iconSize: 20,
                ),
            ],
          ),
        ],
      ),
    );
  }
  
  // ENHANCED: Helper method to extract filename from URL
  String _extractFileNameFromUrl(String url) {
    try {
      print('🔍 Extracting filename from URL: $url');
      
      final uri = Uri.parse(url);
      print('   - URI path: ${uri.path}');
      print('   - URI pathSegments: ${uri.pathSegments}');
      
      String fileName = '';
      
      if (uri.pathSegments.isNotEmpty) {
        fileName = uri.pathSegments.last;
        // Remove URL encoding if present
        fileName = Uri.decodeComponent(fileName);
      } else if (uri.path.isNotEmpty) {
        // Fallback to simple path splitting
        final pathParts = uri.path.split('/');
        if (pathParts.isNotEmpty) {
          fileName = pathParts.last;
        }
      }
      
      // Remove query parameters if present
      if (fileName.contains('?')) {
        fileName = fileName.split('?').first;
      }
      
      // If still no proper filename, provide a default
      if (fileName.isEmpty || fileName.length < 3) {
        // Try to detect file type from URL and provide appropriate default
        if (url.toLowerCase().contains('pdf')) {
          fileName = 'Document.pdf';
        } else if (url.toLowerCase().contains('doc')) {
          fileName = 'Document.doc';
        } else if (url.toLowerCase().contains('jpg') || url.toLowerCase().contains('jpeg')) {
          fileName = 'Image.jpg';
        } else if (url.toLowerCase().contains('png')) {
          fileName = 'Image.png';
        } else {
          fileName = 'Job Description Document';
        }
      }
      
      print('✅ Extracted filename: $fileName');
      return fileName;
    } catch (e) {
      print('❌ Error extracting filename from URL: $e');
      // Final fallback
      if (url.contains('/')) {
        final parts = url.split('/');
        if (parts.isNotEmpty && parts.last.isNotEmpty) {
          String fileName = parts.last;
          if (fileName.contains('?')) {
            fileName = fileName.split('?').first;
          }
          return fileName.isNotEmpty ? fileName : 'Uploaded Document';
        }
      }
      return 'Uploaded Document';
    }
  }
}
