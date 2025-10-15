import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../models/form_builder/form_field.dart' as form_models;

/// Preview File Field - Functional file upload
class PreviewFileField extends StatefulWidget {
  final form_models.FormField field;
  final dynamic value;
  final Function(dynamic) onChanged;
  final bool hasError;
  
  const PreviewFileField({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
    this.hasError = false,
  });

  @override
  State<PreviewFileField> createState() => _PreviewFileFieldState();
}

class _PreviewFileFieldState extends State<PreviewFileField> {
  List<PlatformFile> _selectedFiles = [];
  final bool _isUploading = false;
  
  @override
  void initState() {
    super.initState();
    if (widget.value is List) {
      // Load existing files if any
      _selectedFiles = List<PlatformFile>.from(widget.value);
    }
  }
 
  Future<void> _pickFiles() async {
    try {
      final allowMultiple = widget.field.props['multiple'] ?? false;
      final maxFiles = widget.field.props['maxFiles'] ?? 5;
      final accept = widget.field.props['accept'] ?? '*';
      
      FileType fileType = FileType.any;
      List<String>? allowedExtensions;
      
      // Determine file type
      if (accept.contains('image')) {
        fileType = FileType.image;
      } else if (accept == '.pdf' || accept.contains('pdf')) {
        fileType = FileType.custom;
        allowedExtensions = ['pdf'];
      } else if (accept.contains('.doc')) {
        fileType = FileType.custom;
        allowedExtensions = ['doc', 'docx'];
      } else if (accept.contains('.xls') || accept.contains('.csv')) {
        fileType = FileType.custom;
        allowedExtensions = ['xls', 'xlsx', 'csv'];
      }
      
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: allowMultiple,
        type: fileType,
        allowedExtensions: allowedExtensions,
      );
      
      if (result != null) {
        setState(() {
          if (allowMultiple) {
            // Check max files
            final newFiles = result.files;
            if (_selectedFiles.length + newFiles.length <= maxFiles) {
              _selectedFiles.addAll(newFiles);
            } else {
              // Show error
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Maximum $maxFiles files allowed'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
          } else {
            _selectedFiles = result.files;
          }
        });
        
        // Notify parent
        widget.onChanged(_selectedFiles);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking files: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
    widget.onChanged(_selectedFiles);
  }

  @override
  Widget build(BuildContext context) {
    final allowMultiple = widget.field.props['multiple'] ?? false;
    final showPreview = widget.field.props['showPreview'] ?? true;
    final showFileSize = widget.field.props['showFileSize'] ?? true;
    final allowRemove = widget.field.props['allowRemove'] ?? true;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Label
        Row(
          children: [
            Text(
              widget.field.label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (widget.field.required)
              const Text(
                ' *',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Upload Button
        OutlinedButton.icon(
          onPressed: _isUploading ? null : _pickFiles,
          icon: const Icon(Icons.attach_file),
          label: Text(
            _selectedFiles.isEmpty
                ? 'Choose File${allowMultiple ? 's' : ''}'
                : 'Add More Files',
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        
        // Selected Files List
        if (_selectedFiles.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: widget.hasError ? Colors.red : Colors.grey[300]!,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _selectedFiles.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[300]),
              itemBuilder: (context, index) {
                final file = _selectedFiles[index];
                return ListTile(
                  dense: true,
                  leading: Icon(
                    _getFileIcon(file.extension),
                    color: Colors.blue,
                  ),
                  title: Text(
                    file.name,
                    style: const TextStyle(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: showFileSize
                      ? Text(
                          _formatFileSize(file.size),
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        )
                      : null,
                  trailing: allowRemove
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => _removeFile(index),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        )
                      : null,
                );
              },
            ),
          ),
        ],
        
        // Help text
        if (widget.field.props['helpText'] != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.field.props['helpText'],
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
        
        // Error message
        if (widget.hasError) ...[
          const SizedBox(height: 8),
          Text(
            'This field is required',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.red,
            ),
          ),
        ],
      ],
    );
  }
  
  IconData _getFileIcon(String? extension) {
    if (extension == null) return Icons.insert_drive_file;
    
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
      case 'csv':
        return Icons.table_chart;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }
  
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
