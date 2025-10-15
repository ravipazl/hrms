import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:uuid/uuid.dart';
import '../../../models/form_builder/form_field.dart' as form_models;
import '../../../models/form_builder/rich_text_config.dart';
import '../../../utils/rich_text_converter.dart';
 
/// Rich Text Editor Widget for Form Builder (Builder Mode)
/// Uses flutter_quill 11.4.2 with simplified embedded field approach
class RichTextEditorWidget extends StatefulWidget {
  final form_models.FormField field;
  final Function(String, Map<String, dynamic>) onFieldUpdate;

  const RichTextEditorWidget({
    super.key,
    required this.field,
    required this.onFieldUpdate,
  });

  @override
  State<RichTextEditorWidget> createState() => _RichTextEditorWidgetState();
}

class _RichTextEditorWidgetState extends State<RichTextEditorWidget> {
  late QuillController _controller;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  late RichTextToolbar _toolbarConfig;

  @override
  void initState() {
    super.initState();
    _initializeEditor();
  }

  void _initializeEditor() {
    // Get toolbar config
    final toolbarData = widget.field.props['toolbar'] as Map<String, dynamic>?;
    _toolbarConfig = toolbarData != null
        ? RichTextToolbar.fromJson(toolbarData)
        : RichTextToolbar();

    // Convert Slate content to Quill
    final slateContent = widget.field.props['content'] as List<dynamic>? ?? [
      {'type': 'paragraph', 'children': [{'text': ''}]}
    ];
    final embeddedFields = widget.field.props['embeddedFields'] as List<dynamic>? ?? [];
    
    final document = RichTextConverter.slateToQuill(
      slateContent,
      embeddedFields.map((e) => e as Map<String, dynamic>).toList(),
    );

    _controller = QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );

    // Listen to changes
    _controller.addListener(_onContentChanged);
  }

  void _onContentChanged() {
    // Convert Quill Delta back to Slate JSON
    final slateContent = RichTextConverter.quillToSlate(_controller.document);
    
    widget.onFieldUpdate(widget.field.id, {
      'content': slateContent,
    });
  }

  void _insertEmbeddedField(String fieldType) {
    final uuid = const Uuid();
    final fieldId = 'field_${DateTime.now().millisecondsSinceEpoch}_${uuid.v4().substring(0, 8)}';
    
    final typeLabels = {
      'text': 'Text Input',
      'number': 'Number Input',
      'email': 'Email Input',
      'date': 'Date Input',
      'select': 'Select Option',
      'checkbox': 'Checkbox',
      'radio': 'Radio Option',
      'textarea': 'Text Area',
    };
    
    final label = typeLabels[fieldType] ?? fieldType;

    // Insert embedded field as specially formatted text (no background color)
    final index = _controller.selection.baseOffset;
    final length = _controller.selection.extentOffset - _controller.selection.baseOffset;
    
    // Format: 🔷[FieldType: Label]
    final fieldIcon = _getFieldIconText(fieldType);
    final embedText = '$fieldIcon [$label] ';
    
    // Simply insert text without formatting to avoid render errors
    _controller.replaceText(
      index,
      length,
      embedText,
      null,
    );

    // Update embedded fields list
    final embeddedFields = List<Map<String, dynamic>>.from(
      widget.field.props['embeddedFields'] as List<dynamic>? ?? [],
    );
    embeddedFields.add({
      'id': fieldId,
      'fieldType': fieldType,
      'label': label,
      'props': {},
    });

    widget.onFieldUpdate(widget.field.id, {
      'embeddedFields': embeddedFields,
    });

    // Move cursor after the embedded field text
    _controller.updateSelection(
      TextSelection.collapsed(offset: index + embedText.length),
      ChangeSource.local,
    );
  }

  String _getFieldIconText(String fieldType) {
    switch (fieldType) {
      case 'text':
        return '📝';
      case 'number':
        return '🔢';
      case 'email':
        return '📧';
      case 'date':
        return '📅';
      case 'select':
        return '📋';
      case 'checkbox':
        return '☑️';
      case 'radio':
        return '🔘';
      case 'textarea':
        return '📄';
      default:
        return '📌';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Column(
        children: [
          // Toolbar
          _buildToolbar(),
          
          // Divider
          Divider(height: 1, color: Colors.grey[300]),
          
          // Editor - Flutter Quill 11.4.2 basic version
          Container(
            constraints: const BoxConstraints(minHeight: 150, maxHeight: 400),
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: SingleChildScrollView(
              controller: _scrollController,
              child: QuillEditor.basic(
                controller: _controller,
                focusNode: _focusNode,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          // Headings
          if (_toolbarConfig.headings) ...[
            _QuillToolbarIconButton(
              icon: Icons.title,
              label: 'H1',
              onPressed: () {
                try {
                  _focusNode.requestFocus();
                  _controller.formatSelection(Attribute.h1);
                } catch (e) {
                  debugPrint('Error formatting H1: $e');
                }
              },
              isSelected: _controller
                  .getSelectionStyle()
                  .attributes
                  .containsKey(Attribute.h1.key),
            ),
            _QuillToolbarIconButton(
              icon: Icons.title,
              label: 'H2',
              onPressed: () {
                try {
                  _focusNode.requestFocus();
                  _controller.formatSelection(Attribute.h2);
                } catch (e) {
                  debugPrint('Error formatting H2: $e');
                }
              },
              isSelected: _controller
                  .getSelectionStyle()
                  .attributes
                  .containsKey(Attribute.h2.key),
            ),
          ],

          // Text formatting
          if (_toolbarConfig.bold)
            _QuillToolbarIconButton(
              icon: Icons.format_bold,
              onPressed: () {
                try {
                  _focusNode.requestFocus();
                  _controller.formatSelection(Attribute.bold);
                } catch (e) {
                  debugPrint('Error formatting bold: $e');
                }
              },
              isSelected: _controller
                  .getSelectionStyle()
                  .attributes
                  .containsKey(Attribute.bold.key),
            ),
          if (_toolbarConfig.italic)
            _QuillToolbarIconButton(
              icon: Icons.format_italic,
              onPressed: () {
                try {
                  _focusNode.requestFocus();
                  _controller.formatSelection(Attribute.italic);
                } catch (e) {
                  debugPrint('Error formatting italic: $e');
                }
              },
              isSelected: _controller
                  .getSelectionStyle()
                  .attributes
                  .containsKey(Attribute.italic.key),
            ),
          if (_toolbarConfig.underline)
            _QuillToolbarIconButton(
              icon: Icons.format_underline,
              onPressed: () {
                try {
                  _focusNode.requestFocus();
                  _controller.formatSelection(Attribute.underline);
                } catch (e) {
                  debugPrint('Error formatting underline: $e');
                }
              },
              isSelected: _controller
                  .getSelectionStyle()
                  .attributes
                  .containsKey(Attribute.underline.key),
            ),
          if (_toolbarConfig.strike)
            _QuillToolbarIconButton(
              icon: Icons.format_strikethrough,
              onPressed: () {
                try {
                  _focusNode.requestFocus();
                  _controller.formatSelection(Attribute.strikeThrough);
                } catch (e) {
                  debugPrint('Error formatting strike: $e');
                }
              },
              isSelected: _controller
                  .getSelectionStyle()
                  .attributes
                  .containsKey(Attribute.strikeThrough.key),
            ),

          // Alignment
          if (_toolbarConfig.align) ...[
            _QuillToolbarIconButton(
              icon: Icons.format_align_left,
              onPressed: () {
                try {
                  _focusNode.requestFocus();
                  _controller.formatSelection(Attribute.leftAlignment);
                } catch (e) {
                  debugPrint('Error aligning left: $e');
                }
              },
            ),
            _QuillToolbarIconButton(
              icon: Icons.format_align_center,
              onPressed: () {
                try {
                  _focusNode.requestFocus();
                  _controller.formatSelection(Attribute.centerAlignment);
                } catch (e) {
                  debugPrint('Error aligning center: $e');
                }
              },
            ),
            _QuillToolbarIconButton(
              icon: Icons.format_align_right,
              onPressed: () {
                try {
                  _focusNode.requestFocus();
                  _controller.formatSelection(Attribute.rightAlignment);
                } catch (e) {
                  debugPrint('Error aligning right: $e');
                }
              },
            ),
          ],

          // Lists
          if (_toolbarConfig.lists) ...[
            _QuillToolbarIconButton(
              icon: Icons.format_list_bulleted,
              onPressed: () {
                try {
                  _focusNode.requestFocus();
                  _controller.formatSelection(Attribute.ul);
                } catch (e) {
                  debugPrint('Error formatting ul: $e');
                }
              },
            ),
            _QuillToolbarIconButton(
              icon: Icons.format_list_numbered,
              onPressed: () {
                try {
                  _focusNode.requestFocus();
                  _controller.formatSelection(Attribute.ol);
                } catch (e) {
                  debugPrint('Error formatting ol: $e');
                }
              },
            ),
          ],

          // Insert field dropdown
          if (_toolbarConfig.insertFields.isNotEmpty) ...[
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              tooltip: 'Insert Field',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 16, color: Colors.blue),
                    SizedBox(width: 4),
                    Text('Insert Field', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              itemBuilder: (context) {
                return _toolbarConfig.insertFields.map((fieldType) {
                  return PopupMenuItem<String>(
                    value: fieldType,
                    child: Row(
                      children: [
                        Icon(
                          _getFieldIcon(fieldType),
                          size: 16,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          fieldType[0].toUpperCase() + fieldType.substring(1),
                        ),
                      ],
                    ),
                  );
                }).toList();
              },
              onSelected: (value) {
                if (value != null) {
                  _insertEmbeddedField(value);
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  // Helper method to get icons for field types
  IconData _getFieldIcon(String fieldType) {
    switch (fieldType) {
      case 'text':
        return Icons.text_fields;
      case 'number':
        return Icons.numbers;
      case 'email':
        return Icons.email;
      case 'date':
        return Icons.calendar_today;
      case 'select':
        return Icons.arrow_drop_down_circle;
      case 'checkbox':
        return Icons.check_box;
      case 'radio':
        return Icons.radio_button_checked;
      case 'textarea':
        return Icons.notes;
      default:
        return Icons.input;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onContentChanged);
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

/// Custom toolbar button widget
class _QuillToolbarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isSelected;
  final String? label;

  const _QuillToolbarIconButton({
    required this.icon,
    required this.onPressed,
    this.isSelected = false,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[100] : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
          ),
        ),
        child: label != null
            ? Text(
                label!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.blue[700] : Colors.grey[700],
                ),
              )
            : Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.blue[700] : Colors.grey[700],
              ),
      ),
    );
  }
}
