import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import '../../../models/form_builder/form_field.dart' as form_models;
import '../../../models/form_builder/rich_text_config.dart';
import '../../../utils/rich_text_converter.dart';

/// COMPLETELY RECONSTRUCTED: Rich Text Editor Widget with Proper State Management
/// All toolbar functions now work correctly with proper toggle logic
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
  
  // State tracking for proper UI updates
  Map<String, dynamic> _currentAttributes = {};
  
  // Debouncing for content updates
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _initializeEditor();
  }

  void _initializeEditor() {
    final toolbarData = widget.field.props['toolbar'] as Map<String, dynamic>?;
    _toolbarConfig = toolbarData != null
        ? RichTextToolbar.fromJson(toolbarData)
        : RichTextToolbar();

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

    _controller.addListener(_onContentChangedDebounced);
    
    // Listen to selection changes for toolbar updates
    _controller.addListener(_onSelectionChanged);
  }

  void _onContentChangedDebounced() {
    // Cancel previous timer if exists
    _debounceTimer?.cancel();
    
    // Set new timer
    _debounceTimer = Timer(_debounceDuration, () {
      if (!mounted) return;
      _onContentChanged();
    });
  }

  void _onContentChanged() {
    final slateContent = RichTextConverter.quillToSlate(_controller.document);
    widget.onFieldUpdate(widget.field.id, {
      'content': slateContent,
    });
  }

  void _onSelectionChanged() {
    // Update current attributes when selection changes
    final style = _controller.getSelectionStyle();
    if (mounted) {
      setState(() {
        _currentAttributes = Map<String, dynamic>.from(style.attributes);
      });
    }
  }

  // ==================== HEADING FUNCTIONS ====================
  
  void _toggleHeading(Attribute<int?> heading) {
    debugPrint('🔷 Toggle Heading: ${heading.key} = ${heading.value}');
    
    final style = _controller.getSelectionStyle();
    final currentHeading = style.attributes[Attribute.header.key];
    
    debugPrint('  Current heading value: $currentHeading');
    debugPrint('  Target heading value: ${heading.value}');
    
    // Check if this exact heading is active
    final isThisHeadingActive = currentHeading != null && 
                                 currentHeading.value == heading.value;
    
    if (isThisHeadingActive) {
      // Remove heading - set to null to clear
      debugPrint('  Action: Removing heading (setting to null)');
      _controller.formatSelection(
        Attribute.fromKeyValue(Attribute.header.key, null)
      );
    } else {
      // Apply new heading - this automatically replaces any existing heading
      debugPrint('  Action: Applying heading ${heading.value}');
      _controller.formatSelection(heading);
    }
    
    // Force UI update
    if (mounted) {
      setState(() {
        _currentAttributes = Map<String, dynamic>.from(_controller.getSelectionStyle().attributes);
      });
    }
  }

  bool _isHeadingActive(Attribute<int?> heading) {
    final style = _controller.getSelectionStyle();
    final currentHeading = style.attributes[Attribute.header.key];
    return currentHeading != null && currentHeading.value == heading.value;
  }

  // ==================== TEXT FORMAT FUNCTIONS ====================
  
  void _toggleInlineFormat(Attribute attribute) {
    debugPrint('🔷 Toggle Format: ${attribute.key}');
    
    final style = _controller.getSelectionStyle();
    final isActive = style.attributes.containsKey(attribute.key);
    
    debugPrint('  Is active: $isActive');
    
    if (isActive) {
      // Remove format
      debugPrint('  Action: Removing format');
      _controller.formatSelection(
        Attribute.fromKeyValue(attribute.key, null)
      );
    } else {
      // Apply format
      debugPrint('  Action: Applying format');
      _controller.formatSelection(attribute);
    }
    
    // Force UI update
    if (mounted) {
      setState(() {
        _currentAttributes = Map<String, dynamic>.from(_controller.getSelectionStyle().attributes);
      });
    }
  }

  bool _isInlineFormatActive(Attribute attribute) {
    final style = _controller.getSelectionStyle();
    return style.attributes.containsKey(attribute.key);
  }

  // ==================== ALIGNMENT FUNCTIONS ====================
  
  void _toggleAlignment(Attribute<String?> alignment) {
    debugPrint('🔷 Toggle Alignment: ${alignment.key} = ${alignment.value}');
    
    final style = _controller.getSelectionStyle();
    final currentAlign = style.attributes[Attribute.align.key];
    
    debugPrint('  Current alignment: $currentAlign');
    
    // Check if this exact alignment is active
    final isThisAlignActive = currentAlign != null && 
                               currentAlign.value == alignment.value;
    
    if (isThisAlignActive) {
      // Remove alignment (back to left/default)
      debugPrint('  Action: Removing alignment');
      _controller.formatSelection(
        Attribute.fromKeyValue(Attribute.align.key, null)
      );
    } else {
      // Apply new alignment
      debugPrint('  Action: Applying alignment ${alignment.value}');
      _controller.formatSelection(alignment);
    }
    
    // Force UI update
    if (mounted) {
      setState(() {
        _currentAttributes = Map<String, dynamic>.from(_controller.getSelectionStyle().attributes);
      });
    }
  }

  bool _isAlignmentActive(Attribute<String?> alignment) {
    final style = _controller.getSelectionStyle();
    final currentAlign = style.attributes[Attribute.align.key];
    
    // Special case: left alignment is default (no attribute)
    if (alignment.value == 'left' || alignment.value == null) {
      return currentAlign == null || currentAlign.value == 'left';
    }
    
    return currentAlign != null && currentAlign.value == alignment.value;
  }

  // ==================== LIST FUNCTIONS ====================
  
  void _toggleList(Attribute attribute) {
    debugPrint('🔷 Toggle List: ${attribute.key}');
    
    final style = _controller.getSelectionStyle();
    final currentList = style.attributes[Attribute.list.key];
    
    debugPrint('  Current list: $currentList');
    debugPrint('  Target list: ${attribute.value}');
    
    // Check if this exact list type is active
    final isThisListActive = currentList != null && 
                              currentList.value == attribute.value;
    
    if (isThisListActive) {
      // Remove list
      debugPrint('  Action: Removing list');
      _controller.formatSelection(
        Attribute.fromKeyValue(Attribute.list.key, null)
      );
    } else {
      // Apply new list type
      debugPrint('  Action: Applying list ${attribute.value}');
      _controller.formatSelection(attribute);
    }
    
    // Force UI update
    if (mounted) {
      setState(() {
        _currentAttributes = Map<String, dynamic>.from(_controller.getSelectionStyle().attributes);
      });
    }
  }

  bool _isListActive(Attribute attribute) {
    final style = _controller.getSelectionStyle();
    final currentList = style.attributes[Attribute.list.key];
    return currentList != null && currentList.value == attribute.value;
  }

  // ==================== EMBEDDED FIELD FUNCTIONS ====================
  
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
    final index = _controller.selection.baseOffset;
    final length = _controller.selection.extentOffset - _controller.selection.baseOffset;
    
    final fieldIcon = _getFieldIconText(fieldType);
    final embedText = '$fieldIcon [$label] ';
    
    _controller.replaceText(index, length, embedText, null);

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

    _controller.updateSelection(
      TextSelection.collapsed(offset: index + embedText.length),
      ChangeSource.local,
    );
  }

  String _getFieldIconText(String fieldType) {
    switch (fieldType) {
      case 'text': return '📝';
      case 'number': return '🔢';
      case 'email': return '📧';
      case 'date': return '📅';
      case 'select': return '📋';
      case 'checkbox': return '☑️';
      case 'radio': return '🔘';
      case 'textarea': return '📄';
      default: return '📌';
    }
  }

  IconData _getFieldIcon(String fieldType) {
    switch (fieldType) {
      case 'text': return Icons.text_fields;
      case 'number': return Icons.numbers;
      case 'email': return Icons.email;
      case 'date': return Icons.calendar_today;
      case 'select': return Icons.arrow_drop_down_circle;
      case 'checkbox': return Icons.check_box;
      case 'radio': return Icons.radio_button_checked;
      case 'textarea': return Icons.notes;
      default: return Icons.input;
    }
  }

  // ==================== UI BUILD ====================

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
          _buildToolbar(),
          Divider(height: 1, color: Colors.grey[300]),
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
          // HEADINGS
          if (_toolbarConfig.headings) ...[
            _ToolbarButton(
              icon: Icons.title,
              label: 'H1',
              onPressed: () => _toggleHeading(Attribute.h1),
              isSelected: _isHeadingActive(Attribute.h1),
            ),
            _ToolbarButton(
              icon: Icons.title,
              label: 'H2',
              onPressed: () => _toggleHeading(Attribute.h2),
              isSelected: _isHeadingActive(Attribute.h2),
            ),
            _ToolbarButton(
              icon: Icons.title,
              label: 'H3',
              onPressed: () => _toggleHeading(Attribute.h3),
              isSelected: _isHeadingActive(Attribute.h3),
            ),
          ],

          // TEXT FORMATTING
          if (_toolbarConfig.bold)
            _ToolbarButton(
              icon: Icons.format_bold,
              onPressed: () => _toggleInlineFormat(Attribute.bold),
              isSelected: _isInlineFormatActive(Attribute.bold),
            ),
          if (_toolbarConfig.italic)
            _ToolbarButton(
              icon: Icons.format_italic,
              onPressed: () => _toggleInlineFormat(Attribute.italic),
              isSelected: _isInlineFormatActive(Attribute.italic),
            ),
          if (_toolbarConfig.underline)
            _ToolbarButton(
              icon: Icons.format_underline,
              onPressed: () => _toggleInlineFormat(Attribute.underline),
              isSelected: _isInlineFormatActive(Attribute.underline),
            ),
          if (_toolbarConfig.strike)
            _ToolbarButton(
              icon: Icons.format_strikethrough,
              onPressed: () => _toggleInlineFormat(Attribute.strikeThrough),
              isSelected: _isInlineFormatActive(Attribute.strikeThrough),
            ),

          // ALIGNMENT
          if (_toolbarConfig.align) ...[
            _ToolbarButton(
              icon: Icons.format_align_left,
              onPressed: () => _toggleAlignment(Attribute.leftAlignment),
              isSelected: _isAlignmentActive(Attribute.leftAlignment),
            ),
            _ToolbarButton(
              icon: Icons.format_align_center,
              onPressed: () => _toggleAlignment(Attribute.centerAlignment),
              isSelected: _isAlignmentActive(Attribute.centerAlignment),
            ),
            _ToolbarButton(
              icon: Icons.format_align_right,
              onPressed: () => _toggleAlignment(Attribute.rightAlignment),
              isSelected: _isAlignmentActive(Attribute.rightAlignment),
            ),
            _ToolbarButton(
              icon: Icons.format_align_justify,
              onPressed: () => _toggleAlignment(Attribute.justifyAlignment),
              isSelected: _isAlignmentActive(Attribute.justifyAlignment),
            ),
          ],

          // LISTS
          if (_toolbarConfig.lists) ...[
            _ToolbarButton(
              icon: Icons.format_list_bulleted,
              onPressed: () => _toggleList(Attribute.ul),
              isSelected: _isListActive(Attribute.ul),
            ),
            _ToolbarButton(
              icon: Icons.format_list_numbered,
              onPressed: () => _toggleList(Attribute.ol),
              isSelected: _isListActive(Attribute.ol),
            ),
          ],

          // INSERT FIELDS
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
                        Icon(_getFieldIcon(fieldType), size: 16, color: Colors.grey[700]),
                        const SizedBox(width: 8),
                        Text(fieldType[0].toUpperCase() + fieldType.substring(1)),
                      ],
                    ),
                  );
                }).toList();
              },
              onSelected: _insertEmbeddedField,
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.removeListener(_onContentChangedDebounced);
    _controller.removeListener(_onSelectionChanged);
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

/// Custom Toolbar Button Widget
class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isSelected;
  final String? label;

  const _ToolbarButton({
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
