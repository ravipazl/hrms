import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/form_builder/form_field.dart' as form_model;

/// FIXED: Read-only field renderer for submission view with proper file/signature handling
class SubmissionFieldRenderer extends StatelessWidget {
  final form_model.FormField field;
  final dynamic value;

  const SubmissionFieldRenderer({
    super.key,
    required this.field,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(),
          const SizedBox(height: 8),
          _buildFieldValue(context),
        ],
      ),
    );
  }

  Widget _buildLabel() {
    return Row(
      children: [
        Expanded(
          child: Text(
            field.label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        if (field.required)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Required',
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFieldValue(BuildContext context) {
    if (value == null || value == '' || (value is List && value.isEmpty)) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
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

    switch (field.type) {
      case form_model.FieldType.richText:
        return _buildRichTextValue();
      case form_model.FieldType.table:
        return _buildTableValue();
      case form_model.FieldType.checkbox:
        return _buildCheckboxValue();
      case form_model.FieldType.checkboxGroup:
        return _buildCheckboxGroupValue();
      case form_model.FieldType.radio:
      case form_model.FieldType.select:
        return _buildSelectValue();
      case form_model.FieldType.file:
        return _buildFileValue(context);
      case form_model.FieldType.signature:
        return _buildSignatureValue();
      case form_model.FieldType.date:
        return _buildDateValue();
      case form_model.FieldType.time:
        return _buildTimeValue();
      default:
        return _buildTextValue();
    }
  }

  // Rich text - render with Slate JSON structure + embedded values
  Widget _buildRichTextValue() {
    debugPrint('\n=== RICH TEXT SUBMISSION DATA ===');
    debugPrint('Value type: ${value.runtimeType}');
    debugPrint('Value: $value');
    
    if (value is Map) {
      final map = value as Map<String, dynamic>;
      debugPrint('Map keys: ${map.keys.toList()}');
      map.forEach((key, val) {
        debugPrint('  [$key]: ${val.runtimeType}');
        if (val is String && val.length < 200) {
          debugPrint('    Value: $val');
        } else if (val is Map) {
          debugPrint('    Map keys: ${(val as Map).keys.toList()}');
        } else if (val is List) {
          debugPrint('    List length: ${(val as List).length}');
        }
      });
    } else if (value is String) {
      debugPrint('String value (first 200 chars): ${value.toString().substring(0, value.toString().length > 200 ? 200 : value.toString().length)}');
    }
    
    debugPrint('\nField props keys: ${field.props.keys.toList()}');
    if (field.props.containsKey('content')) {
      debugPrint('Field has content in props: ${field.props['content'].runtimeType}');
    }
    if (field.props.containsKey('embeddedFields')) {
      final embedded = field.props['embeddedFields'] as List?;
      debugPrint('Embedded fields count: ${embedded?.length ?? 0}');
      if (embedded != null && embedded.isNotEmpty) {
        for (var ef in embedded) {
          if (ef is Map) {
            debugPrint('  - ${ef['label']} (${ef['id']}): ${ef['fieldType']}');
          }
        }
      }
    }
    debugPrint('=================================\n');
    
    // NEW FORMAT: Check if value contains Slate structure with embedded values
    if (value is Map) {
      final valueMap = value as Map<String, dynamic>;
      
      // Check if this is the new format with slateContent + embeddedValues
      if (valueMap.containsKey('slateContent') || valueMap.containsKey('content')) {
        return _buildSlateWithFormatting(valueMap);
      }
      
      // Old format: Try to extract HTML
      final htmlContent = valueMap['html'] as String? ?? 
                         valueMap['textContent'] as String? ?? '';
      if (htmlContent.isNotEmpty) {
        return _buildHtmlContent(htmlContent);
      }
    }
    
    // OLD FORMAT: Direct HTML string
    if (value is String) {
      return _buildHtmlContent(value.toString());
    }
    
    return const Text('No content', style: TextStyle(color: Colors.grey));
  }
  
  // NEW: Render Slate JSON with formatting properties
  Widget _buildSlateWithFormatting(Map<String, dynamic> data) {
    // Get Slate content from field definition (template structure)
    final slateContent = field.props['content'] as List<dynamic>? ?? 
                        data['slateContent'] as List<dynamic>? ?? 
                        data['content'] as List<dynamic>? ?? [];
    
    // Get embedded field values from submission data - CHECK ALL POSSIBLE KEYS!
    final embeddedValues = data['embeddedFieldValues'] as Map<String, dynamic>? ??  // ✅ CORRECT KEY!
                          data['embeddedValues'] as Map<String, dynamic>? ?? 
                          data['values'] as Map<String, dynamic>? ?? {};
    
    debugPrint('📋 Slate elements: ${slateContent.length}');
    debugPrint('📋 Embedded field values: $embeddedValues');
    
    if (slateContent.isEmpty) {
      return const Text('No content', style: TextStyle(color: Colors.grey));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: slateContent.map((element) {
        return _buildSlateElement(
          element as Map<String, dynamic>, 
          embeddedValues,
        );
      }).toList(),
    );
  }
  
  Widget _buildSlateElement(
    Map<String, dynamic> element, 
    Map<String, dynamic> embeddedValues,
  ) {
    final type = element['type'] as String?;
    final children = element['children'] as List<dynamic>? ?? [];
    final align = element['align'] as String?;
    
    final baseStyle = _getSlateTextStyle(type);

    // Handle lists
    if (type == 'bulleted-list' || type == 'numbered-list') {
      return _buildSlateList(type, children, baseStyle, embeddedValues);
    }

    // Determine text alignment
    TextAlign textAlign = TextAlign.left;
    if (align == 'center') {
      textAlign = TextAlign.center;
    } else if (align == 'right') {
      textAlign = TextAlign.right;
    } else if (align == 'justify') {
      textAlign = TextAlign.justify;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SelectableText.rich(
        TextSpan(
          children: _buildSlateTextSpans(children, baseStyle, embeddedValues),
        ),
        textAlign: textAlign,
      ),
    );
  }
  
  List<InlineSpan> _buildSlateTextSpans(
    List<dynamic> children,
    TextStyle baseStyle,
    Map<String, dynamic> embeddedValues,
  ) {
    final List<InlineSpan> spans = [];

    for (var child in children) {
      if (child is Map<String, dynamic> && child.containsKey('text')) {
        final text = child['text'] as String;

        // Check if text contains embedded field markers
        if (_containsEmbeddedField(text)) {
          spans.addAll(_parseSlateTextWithFields(
            text, 
            child, 
            baseStyle, 
            embeddedValues,
          ));
        } else if (text.isNotEmpty) {
          spans.add(_createSlateTextSpan(text, child, baseStyle));
        }
      }
    }

    return spans;
  }
  
  List<InlineSpan> _parseSlateTextWithFields(
    String text,
    Map<String, dynamic> styling,
    TextStyle baseStyle,
    Map<String, dynamic> embeddedValues,
  ) {
    final List<InlineSpan> spans = [];
    final emojiPattern = RegExp(r'([📝🔢📧📅📋☑️🔘📄📌])\s*\[(.*?)\]\s*');

    int lastMatchEnd = 0;
    final matches = emojiPattern.allMatches(text);

    for (var match in matches) {
      // Add text before the field
      if (match.start > lastMatchEnd) {
        final beforeText = text.substring(lastMatchEnd, match.start);
        if (beforeText.isNotEmpty) {
          spans.add(_createSlateTextSpan(beforeText, styling, baseStyle));
        }
      }

      final label = match.group(2) ?? '';
      final embeddedField = _findEmbeddedFieldByLabel(label);

      if (embeddedField != null) {
        final fieldId = embeddedField['id'] as String;
        final fieldValue = embeddedValues[fieldId];

        // Show the value if exists, otherwise show placeholder
        if (fieldValue != null && fieldValue.toString().isNotEmpty) {
          spans.add(TextSpan(
            text: ' ${fieldValue.toString()} ',
            style: _applySlateTextStyling(baseStyle, styling).copyWith(
              backgroundColor: Colors.blue.shade50,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade900,
            ),
          ));
        } else {
          spans.add(TextSpan(
            text: ' [$label] ',
            style: _applySlateTextStyling(baseStyle, styling).copyWith(
              color: Colors.grey.shade400,
              fontStyle: FontStyle.italic,
              backgroundColor: Colors.grey.shade100,
            ),
          ));
        }
      } else {
        spans.add(_createSlateTextSpan('[${label}]', styling, baseStyle));
      }

      lastMatchEnd = match.end;
    }

    // Add remaining text
    if (lastMatchEnd < text.length) {
      final remainingText = text.substring(lastMatchEnd);
      if (remainingText.isNotEmpty) {
        spans.add(_createSlateTextSpan(remainingText, styling, baseStyle));
      }
    }

    return spans;
  }
  
  Map<String, dynamic>? _findEmbeddedFieldByLabel(String label) {
    final embeddedFields = field.props['embeddedFields'] as List<dynamic>? ?? [];
    for (var field in embeddedFields) {
      if (field is Map && field['label'] == label) {
        return Map<String, dynamic>.from(field);
      }
    }
    return null;
  }
  
  Widget _buildSlateList(
    String? type,
    List<dynamic> children,
    TextStyle baseStyle,
    Map<String, dynamic> embeddedValues,
  ) {
    final isNumbered = type == 'numbered-list';
    
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isNumbered ? '1. ' : '• ',
            style: baseStyle,
          ),
          Expanded(
            child: SelectableText.rich(
              TextSpan(
                children: _buildSlateTextSpans(children, baseStyle, embeddedValues),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  TextSpan _createSlateTextSpan(
    String text,
    Map<String, dynamic> styling,
    TextStyle baseStyle,
  ) {
    return TextSpan(
      text: text,
      style: _applySlateTextStyling(baseStyle, styling),
    );
  }
  
  TextStyle _getSlateTextStyle(String? type) {
    switch (type) {
      case 'heading-one':
      case 'h1':
        return const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          height: 1.3,
          color: Colors.black87,
        );
      case 'heading-two':
      case 'h2':
        return const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          height: 1.3,
          color: Colors.black87,
        );
      case 'heading-three':
      case 'h3':
        return const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          height: 1.3,
          color: Colors.black87,
        );
      case 'blockquote':
        return const TextStyle(
          fontSize: 14,
          height: 1.5,
          fontStyle: FontStyle.italic,
          color: Colors.black54,
        );
      default:
        return const TextStyle(
          fontSize: 14,
          height: 1.5,
          color: Colors.black87,
        );
    }
  }
  
  bool _containsEmbeddedField(String text) {
    final emojiPattern = RegExp(r'[📝🔢📧📅📋☑️🔘📄📌]\s*\[.*?\]');
    return emojiPattern.hasMatch(text);
  }
  
  TextStyle _applySlateTextStyling(TextStyle baseStyle, Map<String, dynamic> styling) {
    TextStyle style = baseStyle;

    if (styling['bold'] == true) {
      style = style.copyWith(fontWeight: FontWeight.bold);
    }
    if (styling['italic'] == true) {
      style = style.copyWith(fontStyle: FontStyle.italic);
    }
    if (styling['underline'] == true) {
      style = style.copyWith(
        decoration: style.decoration != null
            ? TextDecoration.combine([style.decoration!, TextDecoration.underline])
            : TextDecoration.underline,
      );
    }
    if (styling['strikethrough'] == true || styling['strike'] == true) {
      style = style.copyWith(
        decoration: style.decoration != null
            ? TextDecoration.combine([style.decoration!, TextDecoration.lineThrough])
            : TextDecoration.lineThrough,
      );
    }
    if (styling['code'] == true) {
      style = style.copyWith(
        fontFamily: 'monospace',
        backgroundColor: Colors.grey[200],
      );
    }

    return style;
  }
  
  // Render HTML content (for old submissions)
  Widget _buildHtmlContent(String htmlContent) {
    return Html(
      data: htmlContent,
      style: {
        "body": Style(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
          fontSize: FontSize(15),
          lineHeight: const LineHeight(1.5),
        ),
        "p": Style(
          margin: Margins.only(bottom: 8),
        ),
        "h1": Style(
          fontSize: FontSize(24),
          fontWeight: FontWeight.bold,
          margin: Margins.only(bottom: 12, top: 8),
        ),
        "h2": Style(
          fontSize: FontSize(20),
          fontWeight: FontWeight.bold,
          margin: Margins.only(bottom: 10, top: 8),
        ),
        "h3": Style(
          fontSize: FontSize(18),
          fontWeight: FontWeight.bold,
          margin: Margins.only(bottom: 8, top: 6),
        ),
        "strong": Style(
          fontWeight: FontWeight.bold,
        ),
        "b": Style(
          fontWeight: FontWeight.bold,
        ),
        "em": Style(
          fontStyle: FontStyle.italic,
        ),
        "i": Style(
          fontStyle: FontStyle.italic,
        ),
        "u": Style(
          textDecoration: TextDecoration.underline,
        ),
        "s": Style(
          textDecoration: TextDecoration.lineThrough,
        ),
        "strike": Style(
          textDecoration: TextDecoration.lineThrough,
        ),
        "ul": Style(
          margin: Margins.only(left: 20, bottom: 8),
          padding: HtmlPaddings.only(left: 20),
        ),
        "ol": Style(
          margin: Margins.only(left: 20, bottom: 8),
          padding: HtmlPaddings.only(left: 20),
        ),
        "li": Style(
          margin: Margins.only(bottom: 4),
          display: Display.listItem,
        ),
        "blockquote": Style(
          margin: Margins.only(left: 20, top: 8, bottom: 8),
          padding: HtmlPaddings.only(left: 12),
          border: Border(
            left: BorderSide(
              color: Colors.grey.shade400,
              width: 4,
            ),
          ),
          backgroundColor: Colors.grey.shade50,
        ),
        "code": Style(
          fontFamily: 'monospace',
          backgroundColor: Colors.grey.shade200,
          padding: HtmlPaddings.all(2),
        ),
        "pre": Style(
          fontFamily: 'monospace',
          backgroundColor: Colors.grey.shade100,
          padding: HtmlPaddings.all(8),
          margin: Margins.only(top: 8, bottom: 8),
        ),
      },
    );
  }

  Widget _buildTableValue() {
    if (value is! List) return _buildTextValue();
    
    final List<dynamic> rows = value;
    if (rows.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          'No table data',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    Set<String> allColumns = {};
    for (final row in rows) {
      if (row is Map) {
        final rowData = row['data'] as Map<String, dynamic>? ?? row;
        if (rowData is Map) {
          allColumns.addAll((rowData as Map<String, dynamic>).keys.cast<String>());
        }
      }
    }
    
    final columnsList = allColumns.toList();
    final tableColumns = _getTableColumnsFromField();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.table_chart, 
                  size: 16, 
                  color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  '${rows.length} row(s) × ${columnsList.length} column(s)',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
              columnSpacing: 24,
              columns: [
                const DataColumn(
                  label: Text(
                    '#',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                ...columnsList.map(
                  (column) => DataColumn(
                    label: Text(
                      tableColumns[column] ?? _formatColumnName(column),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
              rows: rows.asMap().entries.map((entry) {
                final index = entry.key;
                final row = entry.value;
                Map<String, dynamic> rowData = {};
                
                if (row is Map) {
                  final data = row['data'];
                  rowData = Map<String, dynamic>.from(data is Map ? data : row);
                }
                
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    ...columnsList.map(
                      (column) => DataCell(
                        Container(
                          constraints: const BoxConstraints(maxWidth: 200),
                          child: Text(
                            rowData[column]?.toString() ?? '-',
                            style: const TextStyle(fontSize: 13),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, String> _getTableColumnsFromField() {
    try {
      if (field.props.containsKey('columns')) {
        final columns = field.props['columns'];
        if (columns is List) {
          final Map<String, String> columnMap = {};
          for (final col in columns) {
            if (col is Map) {
              final id = col['id']?.toString();
              final label = col['label']?.toString() ?? col['name']?.toString();
              if (id != null && label != null) {
                columnMap[id] = label;
              }
            }
          }
          return columnMap;
        }
      }
    } catch (e) {
      debugPrint('Error parsing table columns: $e');
    }
    return {};
  }

  String _formatColumnName(String columnName) {
    String formatted = columnName
        .replaceFirst(RegExp(r'^field_'), '')
        .replaceFirst(RegExp(r'^col_'), '');
    formatted = formatted
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return formatted
        .split(' ')
        .map((word) => word.isEmpty
            ? ''
            : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  Widget _buildCheckboxValue() {
    final isChecked = value == true || value.toString().toLowerCase() == 'true';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(
            isChecked ? Icons.check_box : Icons.check_box_outline_blank,
            color: isChecked ? Colors.green : Colors.grey,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            isChecked ? 'Yes' : 'No',
            style: const TextStyle(fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxGroupValue() {
    final List<dynamic> items = value is List ? value : [value];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items
            .map(
              (item) => Chip(
                label: Text(item.toString()),
                backgroundColor: Colors.blue.shade50,
                side: BorderSide(color: Colors.blue.shade200),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildSelectValue() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        value.toString(),
        style: const TextStyle(fontSize: 15),
      ),
    );
  }

  // FIXED: File field with proper download links
  Widget _buildFileValue(BuildContext context) {
    debugPrint('📎 File Value Type: ${value.runtimeType}');
    debugPrint('📎 File Value: $value');
    
    List<dynamic> files = [];
    
    if (value is List) {
      files = value;
    } else if (value is String) {
      // Handle single file as string (filename or file reference)
      files = [{'filename': value, 'originalName': value}];
    } else if (value is Map) {
      files = [value];
    }
    
    if (files.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          'No files uploaded',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_file, size: 16, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                '${files.length} file(s) uploaded',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...files.map<Widget>((file) {
            String fileName = 'Unknown file';
            String? fileSize;
            String? fileUrl;
            
            if (file is Map) {
              fileName = file['originalName']?.toString() ??
                  file['filename']?.toString() ??
                  file['name']?.toString() ??
                  'Unknown file';
              fileSize = file['size']?.toString();
              fileUrl = file['url']?.toString() ??
                  file['fileUrl']?.toString() ??
                  file['path']?.toString();
              
              // Construct file URL if we only have filename
              if (fileUrl == null && file['filename'] != null) {
                fileUrl = 'http://127.0.0.1:8000/media/form_builder_uploads/${file['filename']}';
              }
            } else if (file is String) {
              fileName = file;
              // Construct file URL from filename
              fileUrl = 'http://127.0.0.1:8000/media/form_builder_uploads/$file';
            }
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    _getFileIcon(fileName),
                    color: Colors.blue.shade600,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fileName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (fileSize != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            _formatFileSize(fileSize),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (fileUrl != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        Icons.download,
                        color: Colors.green.shade600,
                        size: 20,
                      ),
                      tooltip: 'Download file',
                      onPressed: () => _downloadFile(context, fileUrl!, fileName),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
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

  void _downloadFile(BuildContext context, String url, String fileName) {
    debugPrint('📥 Downloading file: $url');
    
    // Show snackbar with download link
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening download: $fileName'),
        action: SnackBarAction(
          label: 'Open',
          onPressed: () async {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not open file')),
                );
              }
            }
          },
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  String _formatFileSize(dynamic size) {
    final bytes = size is int ? size : int.tryParse(size.toString()) ?? 0;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // FIXED: Signature field with file reference handling
  Widget _buildSignatureValue() {
    debugPrint('🖊️ === SIGNATURE RENDERER ===');
    debugPrint('🖊️ Value type: ${value.runtimeType}');
    debugPrint('🖊️ Value preview: ${value.toString().substring(0, value.toString().length > 100 ? 100 : value.toString().length)}...');
    
    String? signatureData;
    String? signatureId;
    String? fileUrl;
    
    // Parse signature value from different formats
    if (value is Map) {
      final signatureMap = value as Map<String, dynamic>;
      signatureData = signatureMap['signature'] as String? ?? 
                      signatureMap['data'] as String? ?? 
                      signatureMap['base64'] as String?;
      signatureId = signatureMap['id'] as String? ?? 
                    signatureMap['signatureId'] as String? ??
                    signatureMap['fileId'] as String?;
      fileUrl = signatureMap['url'] as String? ?? 
                signatureMap['fileUrl'] as String?;
    } else if (value is String) {
      final stringValue = value as String;
      
      // Check if it's a file reference (signature_XXXXX format)
      if (stringValue.startsWith('signature_')) {
        signatureId = stringValue;
        // Construct file URL from backend
        fileUrl = 'http://127.0.0.1:8000/media/form_builder_uploads/$stringValue';
        debugPrint('🖊️ File reference detected, URL: $fileUrl');
      }
      // Check if it's a relative path starting with /media/
      else if (stringValue.startsWith('/media/')) {
        signatureId = stringValue.split('/').last;
        // Already a path, just prepend domain
        fileUrl = 'http://127.0.0.1:8000$stringValue';
        debugPrint('🖊️ Relative path detected, URL: $fileUrl');
      } 
      // Check if it's a data URL
      else if (stringValue.startsWith('data:image/')) {
        signatureData = stringValue;
      }
      // Check if it's base64 without data URL prefix
      else if (_isValidBase64(stringValue) && stringValue.length > 100) {
        signatureData = stringValue;
      }
      // Otherwise treat as file reference
      else {
        signatureId = stringValue;
        fileUrl = 'http://127.0.0.1:8000/media/form_builder_uploads/$stringValue';
      }
    }
    
    debugPrint('🖊️ Signature render decision:');
    debugPrint('  - fileUrl: $fileUrl');
    debugPrint('  - signatureData: ${signatureData != null ? "present (${signatureData!.length} chars)" : "null"}');
    debugPrint('  - signatureId: $signatureId');
    
    // CASE 1: We have a file URL - show image from network
    if (fileUrl != null) {
      debugPrint('🌐 Using network image from URL: $fileUrl');
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.draw, size: 20, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Signature',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Image container
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 250, minHeight: 120),
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.white,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      fileUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('🖊️ Error loading signature from URL: $error');
                        return Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Signature image not available',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                              if (signatureId != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'File: $signatureId',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Colors.green.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      signatureId != null
                          ? 'Signature file: $signatureId'
                          : 'Signature captured',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    
    // CASE 2: We have base64/data URL - decode and show
    if (signatureData != null) {
      bool isDataUrl = signatureData.startsWith('data:image/');
      
      try {
        Uint8List imageBytes;
        if (isDataUrl) {
          final parts = signatureData.split(',');
          if (parts.length < 2) {
            throw const FormatException('Invalid data URL format');
          }
          imageBytes = base64Decode(parts[1]);
        } else {
          imageBytes = base64Decode(signatureData);
        }
        
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.draw, size: 20, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Signature',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 250, minHeight: 120),
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.memory(
                        imageBytes,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Signature captured (${_formatFileSize(imageBytes.length)})',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      } catch (e) {
        debugPrint('🖊️ Error decoding signature: $e');
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Signature data error',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Could not decode signature: ${e.toString()}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      }
    }
    
    // CASE 3: No signature data
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.draw, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Text(
            'No signature captured',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  bool _isValidBase64(String str) {
    if (str.isEmpty) return false;
    final base64Regex = RegExp(r'^[A-Za-z0-9+/]*={0,2}$');
    return base64Regex.hasMatch(str) && str.length % 4 == 0;
  }

  Widget _buildDateValue() {
    try {
      final date = DateTime.parse(value.toString());
      final formatted = DateFormat('MMMM dd, yyyy').format(date);
      return _buildFormattedValue(formatted, Icons.calendar_today);
    } catch (e) {
      return _buildFormattedValue(value.toString(), Icons.calendar_today);
    }
  }

  Widget _buildTimeValue() {
    return _buildFormattedValue(value.toString(), Icons.access_time);
  }

  Widget _buildTextValue() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        value.toString(),
        style: const TextStyle(fontSize: 15),
      ),
    );
  }

  Widget _buildFormattedValue(String text, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
