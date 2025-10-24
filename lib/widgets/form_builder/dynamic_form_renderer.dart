import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/form_builder/form_field.dart' as form_model;
import '../../models/form_builder/form_template.dart';
import '../../models/form_builder/form_submission.dart';

/// Dynamic Form Renderer - Shows form exactly as it was built, with submitted values
class DynamicFormRenderer extends StatelessWidget {
  final FormTemplate template;
  final FormSubmission submission;

  const DynamicFormRenderer({
    super.key,
    required this.template,
    required this.submission,
  });

  @override
  Widget build(BuildContext context) {
    if (template.reactFormData == null) {
      return const Center(
        child: Text('Template structure not available'),
      );
    }

    final formData = template.reactFormData!;
    final fields = formData.fields;
    final submittedData = submission.formData;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section (like form builder preview)
          _buildHeader(context, formData),
          
          // Fields Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: fields.map((field) {
                final value = submittedData[field.id];
                return _buildFieldWithValue(context, field, value);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Build header section matching form builder preview
  Widget _buildHeader(BuildContext context, dynamic formData) {
    final headerConfig = formData.headerConfig;
    final showHeader = headerConfig?.showHeader ?? true;
    
    if (!showHeader) {
      return const SizedBox.shrink();
    }

    final backgroundColor = _parseColor(headerConfig?.backgroundColor) ?? Colors.blue.shade700;
    final textColor = _parseColor(headerConfig?.textColor) ?? Colors.white;
    final logoUrl = headerConfig?.logoUrl as String?;
    final alignment = headerConfig?.alignment as String? ?? 'center';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: _getAlignment(alignment),
        children: [
          if (logoUrl != null && logoUrl.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                logoUrl,
                height: 60,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.image, size: 60, color: textColor.withOpacity(0.5)),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            formData.formTitle ?? 'Form',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            textAlign: _getTextAlign(alignment),
          ),
          if (formData.formDescription?.isNotEmpty ?? false) ...[
            const SizedBox(height: 8),
            Text(
              formData.formDescription!,
              style: TextStyle(
                fontSize: 16,
                color: textColor.withOpacity(0.9),
              ),
              textAlign: _getTextAlign(alignment),
            ),
          ],
        ],
      ),
    );
  }

  /// Build field with submitted value - matches field type from form builder
  Widget _buildFieldWithValue(BuildContext context, form_model.FormField field, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Field Label
          Row(
            children: [
              Expanded(
                child: Text(
                  field.label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (field.required)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    'Required',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Field Value Display
          _buildFieldValueDisplay(context, field, value),
        ],
      ),
    );
  }

  /// Build field value display based on field type
  Widget _buildFieldValueDisplay(BuildContext context, form_model.FormField field, dynamic value) {
    // Empty state
    if (value == null || value == '') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          'No response',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    // Render based on field type
    switch (field.type) {
      case form_model.FieldType.text:
      case form_model.FieldType.email:
      case form_model.FieldType.tel:
      case form_model.FieldType.url:
      case form_model.FieldType.number:
        return _buildTextFieldDisplay(value);

      case form_model.FieldType.textarea:
        return _buildTextAreaDisplay(value);

      case form_model.FieldType.select:
      case form_model.FieldType.radio:
        return _buildSelectDisplay(value);

      case form_model.FieldType.checkbox:
        return _buildCheckboxDisplay(value);

      case form_model.FieldType.checkboxGroup:
        return _buildCheckboxGroupDisplay(value);

      case form_model.FieldType.date:
        return _buildDateDisplay(value);

      case form_model.FieldType.time:
        return _buildTimeDisplay(value);

      case form_model.FieldType.file:
        return _buildFileDisplay(value);

      case form_model.FieldType.signature:
        return _buildSignatureDisplay(value);

      case form_model.FieldType.richText:
        return _buildRichTextDisplay(value);

      case form_model.FieldType.table:
        return _buildTableDisplay(value);

      default:
        return _buildTextFieldDisplay(value);
    }
  }

  // Display builders for each field type

  Widget _buildTextFieldDisplay(dynamic value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200, width: 2),
      ),
      child: Text(
        value.toString(),
        style: const TextStyle(fontSize: 16, color: Colors.black87),
      ),
    );
  }

  Widget _buildTextAreaDisplay(dynamic value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200, width: 2),
      ),
      child: Text(
        value.toString(),
        style: const TextStyle(fontSize: 16, color: Colors.black87),
      ),
    );
  }

  Widget _buildSelectDisplay(dynamic value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade300, width: 2),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value.toString(),
              style: TextStyle(
                fontSize: 16,
                color: Colors.blue.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxDisplay(dynamic value) {
    final isChecked = value == true || value.toString().toLowerCase() == 'true';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isChecked ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isChecked ? Colors.green.shade300 : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isChecked ? Icons.check_box : Icons.check_box_outline_blank,
            color: isChecked ? Colors.green.shade700 : Colors.grey.shade600,
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            isChecked ? 'Yes' : 'No',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isChecked ? Colors.green.shade900 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxGroupDisplay(dynamic value) {
    final List<dynamic> items = value is List ? value : [value];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items.map((item) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green.shade300, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade700, size: 18),
              const SizedBox(width: 8),
              Text(
                item.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.green.shade900,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateDisplay(dynamic value) {
    try {
      final date = DateTime.parse(value.toString());
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.purple.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.purple.shade300, width: 2),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.purple.shade700, size: 20),
            const SizedBox(width: 12),
            Text(
              DateFormat('MMMM dd, yyyy').format(date),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.purple.shade900,
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      return _buildTextFieldDisplay(value);
    }
  }

  Widget _buildTimeDisplay(dynamic value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade300, width: 2),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time, color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 12),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.orange.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileDisplay(dynamic value) {
    if (value is! List) {
      return _buildTextFieldDisplay(value);
    }

    final files = value as List;
    return Column(
      children: files.map<Widget>((file) {
        if (file is! Map) return _buildTextFieldDisplay(file);
        
        final fileName = file['originalName'] ?? file['filename'] ?? 'Unknown file';
        final fileSize = file['size'];
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade300, width: 2),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.attach_file, color: Colors.blue.shade700),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName.toString(),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    if (fileSize != null)
                      Text(
                        _formatFileSize(fileSize),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSignatureDisplay(dynamic value) {
    if (value is String && value.startsWith('data:image')) {
      // Base64 image
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300, width: 2),
        ),
        child: Column(
          children: [
            const Icon(Icons.draw, size: 40, color: Colors.grey),
            const SizedBox(height: 8),
            const Text('Signature captured'),
            // TODO: Display base64 image
          ],
        ),
      );
    }
    return _buildTextFieldDisplay(value);
  }

  Widget _buildRichTextDisplay(dynamic value) {
    if (value is Map) {
      final content = value['content'] ?? value['textContent'] ?? '';
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.shade300, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.text_format, color: Colors.amber.shade700, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Rich Text Content',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _stripHtmlTags(content.toString()),
              style: const TextStyle(fontSize: 15),
            ),
          ],
        ),
      );
    }
    return _buildTextFieldDisplay(value);
  }

  Widget _buildTableDisplay(dynamic value) {
    if (value is! List) return _buildTextFieldDisplay(value);
    
    final List<dynamic> rows = value;
    if (rows.isEmpty) {
      return const Text('No data');
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            ),
            child: Row(
              children: [
                Icon(Icons.table_chart, color: Colors.grey.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${rows.length} row(s)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
          // Rows
          ...rows.asMap().entries.map((entry) {
            final index = entry.key;
            final row = entry.value;
            final rowData = row is Map ? (row['data'] ?? row) : <String, dynamic>{};
            
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: index.isEven ? Colors.white : Colors.grey.shade50,
                border: index > 0
                    ? Border(top: BorderSide(color: Colors.grey.shade300))
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: (rowData as Map<dynamic, dynamic>).entries.map((cell) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            '${cell.key}:',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            cell.value.toString(),
                            style: const TextStyle(color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // Helper methods

  Color? _parseColor(dynamic colorValue) {
    if (colorValue == null) return null;
    try {
      final colorString = colorValue.toString().replaceAll('#', '');
      return Color(int.parse('FF$colorString', radix: 16));
    } catch (e) {
      return null;
    }
  }

  CrossAxisAlignment _getAlignment(String alignment) {
    switch (alignment.toLowerCase()) {
      case 'left':
        return CrossAxisAlignment.start;
      case 'right':
        return CrossAxisAlignment.end;
      case 'center':
      default:
        return CrossAxisAlignment.center;
    }
  }

  TextAlign _getTextAlign(String alignment) {
    switch (alignment.toLowerCase()) {
      case 'left':
        return TextAlign.left;
      case 'right':
        return TextAlign.right;
      case 'center':
      default:
        return TextAlign.center;
    }
  }

  String _stripHtmlTags(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  String _formatFileSize(dynamic size) {
    final bytes = size is int ? size : int.tryParse(size.toString()) ?? 0;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
