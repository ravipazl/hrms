import 'package:flutter/material.dart';
import '../../../../models/form_builder/form_field.dart' as form_models;

/// Rich Text Field Renderer for Form Preview (Preview/Submission Mode)
/// PERFECTLY UNIFORM - All fields identical styling with INLINE LAYOUT
class PreviewRichTextField extends StatefulWidget {
  final form_models.FormField field;
  final dynamic value;
  final Function(dynamic) onChanged;
  final bool hasError;

  const PreviewRichTextField({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
    this.hasError = false,
  });
 
  @override
  State<PreviewRichTextField> createState() => _PreviewRichTextFieldState();
}

class _PreviewRichTextFieldState extends State<PreviewRichTextField> {
  Map<String, dynamic> _fieldValues = {};
  List<Map<String, dynamic>> _embeddedFields = [];
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _initializeEmbeddedFields();
    _initializeValues();
    _initializeControllers();
    
    // Call immediately to ensure proper structure is set before submission
    _notifyParent();
  }

  void _initializeEmbeddedFields() {
    _embeddedFields = (widget.field.props['embeddedFields'] as List<dynamic>?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        [];
  }

  void _initializeValues() {
    if (widget.value is Map) {
      _fieldValues = Map<String, dynamic>.from(widget.value as Map);
    }
  }

  void _initializeControllers() {
    for (var field in _embeddedFields) {
      final fieldId = field['id'] as String;
      final fieldType = field['fieldType'] as String;
      
      if (fieldType == 'text' || fieldType == 'email' || fieldType == 'url' || 
          fieldType == 'tel' || fieldType == 'number') {
        final value = _fieldValues[fieldId];
        _controllers[fieldId] = TextEditingController(text: value?.toString() ?? '');
      }
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(PreviewRichTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update if the value actually changed from outside
    if (widget.value != oldWidget.value && widget.value is Map) {
      final newValues = Map<String, dynamic>.from(widget.value as Map);
      // Update controllers only for fields that changed externally
      newValues.forEach((key, value) {
        if (_controllers.containsKey(key) && _fieldValues[key] != value) {
          _controllers[key]?.text = value?.toString() ?? '';
          _fieldValues[key] = value;
        }
      });
    }
  }

  void _handleEmbeddedFieldChange(String fieldId, dynamic value) {
    // Update internal state WITHOUT setState to avoid rebuild/data loss
    _fieldValues[fieldId] = value;
    
    // Always send proper rich text object structure to backend
    _notifyParent();
  }
  
  void _notifyParent() {
    // CRITICAL FIX: Build HTML by merging template content with inline field values
    print('📤 Rich text building merged HTML...');
    
    // Extract template content from field props
    final slateContent = widget.field.props['content'] as List<dynamic>? ?? [];
    final buffer = StringBuffer('<p>');
    
    // Process each slate element to build HTML
    for (var element in slateContent) {
      if (element is Map<String, dynamic>) {
        final children = element['children'] as List<dynamic>? ?? [];
        
        for (var child in children) {
          if (child is Map<String, dynamic> && child.containsKey('text')) {
            final text = child['text'] as String;
            
            // Replace inline field placeholders with actual values
            final mergedText = _replaceInlineFieldPlaceholders(text);
            buffer.write(mergedText);
          }
        }
      }
    }
    
    buffer.write('</p>');
    
    // Clean up: remove excessive whitespace, newlines, AND all emojis
    var mergedHtml = buffer.toString()
        .replaceAll('\n\n', ' ')  // Replace double newlines with space
        .replaceAll('\n', ' ')     // Replace single newlines with space
        .replaceAll(RegExp(r'\s+'), ' ')  // Collapse multiple spaces
        .replaceAll(RegExp(r'[📝🔢📧📅📋☑️🔘📄📌]'), '')  // Remove all emojis
        .trim();
    
    // Ensure we have at least empty paragraph
    if (mergedHtml == '<p></p>' || mergedHtml == '<p> </p>') {
      mergedHtml = '<p></p>';
    }
    
    print('📏 Merged HTML: $mergedHtml');
    print('📋 Inline values: $_fieldValues');
    print('📐 HTML length: ${mergedHtml.length} characters');
    
    // Send the merged HTML string to parent
    widget.onChanged(mergedHtml);
  }
  
  /// Replace placeholders like [Text Input] with actual field values
  String _replaceInlineFieldPlaceholders(String text) {
    // Pattern to match emoji + [Label]
    final emojiPattern = RegExp(r'([📝🔢📧📅📋☑️🔘📄📌])\s*\[(.*?)\]\s*');
    
    return text.replaceAllMapped(emojiPattern, (match) {
      final label = match.group(2) ?? '';
      final embeddedField = _findEmbeddedFieldByLabel(label);
      
      if (embeddedField != null) {
        final fieldId = embeddedField['id'] as String;
        final fieldValue = _fieldValues[fieldId];
        
        // Replace emoji + [Label] with just the value (no emoji, no placeholder)
        if (fieldValue != null && fieldValue.toString().isNotEmpty) {
          return fieldValue.toString();
        } else {
          // If no value, keep the placeholder but remove emoji
          return '[${label}]';
        }
      }
      
      // Keep original if no matching field found
      return match.group(0) ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildRichTextContent();
  }

  Widget _buildRichTextContent() {
    final slateContent = widget.field.props['content'] as List<dynamic>? ?? [];

    if (slateContent.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: slateContent.map((element) {
        return _buildSlateElement(element as Map<String, dynamic>);
      }).toList(),
    );
  }

  Widget _buildSlateElement(Map<String, dynamic> element) {
    final type = element['type'] as String?;
    final children = element['children'] as List<dynamic>? ?? [];
    final align = element['align'] as String?;
    
    final baseStyle = _getTextStyleForType(type);

    if (type == 'bulleted-list' || type == 'numbered-list') {
      return _buildListElement(type, children, baseStyle);
    }

    WrapAlignment wrapAlign = WrapAlignment.start;
    
    if (align == 'center') {
      wrapAlign = WrapAlignment.center;
    } else if (align == 'right') {
      wrapAlign = WrapAlignment.end;
    }

    // Use Wrap for inline layout with proper hit testing
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        alignment: wrapAlign,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 0,
        runSpacing: 0,
        children: _buildInlineWidgetsWithText(children, baseStyle),
      ),
    );
  }

  // Build inline spans with interactive fields using WidgetSpan
  List<InlineSpan> _buildInlineSpansWithInteractiveFields(List<dynamic> children, TextStyle baseStyle) {
    final List<InlineSpan> spans = [];

    for (var child in children) {
      if (child is Map<String, dynamic> && child.containsKey('text')) {
        final text = child['text'] as String;

        if (_containsEmbeddedFieldMarker(text)) {
          // Parse and add text + fields as spans
          spans.addAll(_parseTextWithFieldsAsInteractiveSpans(text, child, baseStyle));
        } else if (text.isNotEmpty) {
          // Add regular text as TextSpan
          spans.add(_createStyledTextSpan(text, child, baseStyle));
        }
      }
    }

    return spans;
  }

  // Build inline widgets with combined text for better layout
  List<Widget> _buildInlineWidgetsWithText(List<dynamic> children, TextStyle baseStyle) {
    final List<Widget> widgets = [];
    String textBuffer = '';
    TextStyle? currentStyle;

    void flushText() {
      if (textBuffer.isNotEmpty) {
        widgets.add(
          SelectableText(
            textBuffer,
            style: currentStyle ?? baseStyle,
          ),
        );
        textBuffer = '';
        currentStyle = null;
      }
    }

    for (var child in children) {
      if (child is Map<String, dynamic> && child.containsKey('text')) {
        final text = child['text'] as String;
        final styling = child;

        if (_containsEmbeddedFieldMarker(text)) {
          // Parse text with fields
          final segments = _parseTextAndFields(text, styling, baseStyle);
          
          for (var segment in segments) {
            if (segment is _TextSegment) {
              // Accumulate text
              if (currentStyle == null) {
                currentStyle = _applyTextStyling(baseStyle, styling);
              }
              textBuffer += segment.text;
            } else if (segment is Widget) {
              // Flush text before field
              flushText();
              // Add field widget
              widgets.add(segment);
            }
          }
        } else if (text.isNotEmpty) {
          // Accumulate regular text
          if (currentStyle == null) {
            currentStyle = _applyTextStyling(baseStyle, styling);
          }
          textBuffer += text;
        }
      }
    }

    // Flush remaining text
    flushText();

    return widgets;
  }

  // Parse text with embedded fields and return list of text segments and widgets
  List<dynamic> _parseTextAndFields(String text, Map<String, dynamic> styling, TextStyle baseStyle) {
    final List<dynamic> items = [];
    final emojiPattern = RegExp(r'([📝🔢📧📅📋☑️🔘📄📌])\s*\[(.*?)\]\s*');

    int lastMatchEnd = 0;
    final matches = emojiPattern.allMatches(text);

    for (var match in matches) {
      // Add text before field
      if (match.start > lastMatchEnd) {
        final beforeText = text.substring(lastMatchEnd, match.start);
        if (beforeText.isNotEmpty) {
          items.add(_TextSegment(beforeText));
        }
      }

      final label = match.group(2) ?? '';
      final embeddedField = _findEmbeddedFieldByLabel(label);

      if (embeddedField != null) {
        final fieldId = embeddedField['id'] as String;
        final fieldType = embeddedField['fieldType'] as String;
        final currentValue = _fieldValues[fieldId];

        // Add field as widget with proper z-index
        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: _buildFieldByType(fieldId, fieldType, label, currentValue),
          ),
        );
      } else {
        // Fallback
        final emoji = match.group(1) ?? '';
        items.add(_TextSegment('$emoji [$label]'));
      }

      lastMatchEnd = match.end;
    }

    // Add remaining text
    if (lastMatchEnd < text.length) {
      final remainingText = text.substring(lastMatchEnd);
      if (remainingText.isNotEmpty) {
        items.add(_TextSegment(remainingText));
      }
    }

    return items;
  }

  // Create TextSpan with proper styling
  TextSpan _createStyledTextSpan(
    String text,
    Map<String, dynamic> styling,
    TextStyle baseStyle,
  ) {
    return TextSpan(
      text: text,
      style: _applyTextStyling(baseStyle, styling),
    );
  }

  // Parse text with embedded fields and return interactive InlineSpans
  List<InlineSpan> _parseTextWithFieldsAsInteractiveSpans(
    String text,
    Map<String, dynamic> styling,
    TextStyle baseStyle,
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
          spans.add(_createStyledTextSpan(beforeText, styling, baseStyle));
        }
      }

      final label = match.group(2) ?? '';
      final embeddedField = _findEmbeddedFieldByLabel(label);

      if (embeddedField != null) {
        final fieldId = embeddedField['id'] as String;
        final fieldType = embeddedField['fieldType'] as String;
        final currentValue = _fieldValues[fieldId];

        // Add interactive field as WidgetSpan with baseline alignment and proper hit testing
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Transform.translate(
              offset: const Offset(0, 2),  // Fine-tune vertical alignment
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: RepaintBoundary(
                  child: _buildFieldByType(fieldId, fieldType, label, currentValue),
                ),
              ),
            ),
          ),
        );
      } else {
        // Fallback: show emoji and label as text
        final emoji = match.group(1) ?? '';
        spans.add(_createStyledTextSpan('$emoji [$label]', styling, baseStyle));
      }

      lastMatchEnd = match.end;
    }

    // Add remaining text after last field
    if (lastMatchEnd < text.length) {
      final remainingText = text.substring(lastMatchEnd);
      if (remainingText.isNotEmpty) {
        spans.add(_createStyledTextSpan(remainingText, styling, baseStyle));
      }
    }

    return spans;
  }

  Widget _buildListElement(String? type, List<dynamic> children, TextStyle baseStyle) {
    final isNumbered = type == 'numbered-list';
    
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 8),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 0,
        runSpacing: 0,
        children: [
          SelectableText(
            isNumbered ? '1. ' : '• ',
            style: baseStyle,
          ),
          ..._buildInlineWidgetsWithText(children, baseStyle),
        ],
      ),
    );
  }

  TextStyle _getTextStyleForType(String? type) {
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

  bool _containsEmbeddedFieldMarker(String text) {
    final emojiPattern = RegExp(r'[📝🔢📧📅📋☑️🔘📄📌]\s*\[.*?\]');
    return emojiPattern.hasMatch(text);
  }

  TextStyle _applyTextStyling(TextStyle baseStyle, Map<String, dynamic> styling) {
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

  Map<String, dynamic>? _findEmbeddedFieldByLabel(String label) {
    for (var field in _embeddedFields) {
      if (field['label'] == label) {
        return field;
      }
    }
    return null;
  }

  Widget _buildFieldByType(
    String fieldId,
    String fieldType,
    String label,
    dynamic currentValue,
  ) {
    switch (fieldType) {
      case 'text':
      case 'email':
      case 'url':
      case 'tel':
        return _buildTextField(fieldId, label, currentValue);
      case 'number':
        return _buildNumberField(fieldId, label, currentValue);
      case 'date':
        return _buildDateField(fieldId, label, currentValue);
      case 'select':
        return _buildSelectField(fieldId, label, currentValue);
      case 'checkbox':
        return _buildCheckboxField(fieldId, label, currentValue);
      default:
        return _buildTextField(fieldId, label, currentValue);
    }
  }

  // UNIFORM FIELD CONTAINER STYLE
  BoxDecoration _getFieldDecoration() {
    return BoxDecoration(
      border: Border.all(color: const Color(0xFF90CAF9), width: 1),  // Light blue border
      borderRadius: BorderRadius.circular(4),
      color: Colors.white,  // White background
    );
  }

  TextStyle _getFieldTextStyle({Color? color}) {
    return TextStyle(
      fontSize: 14,
      height: 1.0,  // Tight line height for better baseline alignment
      color: color ?? Colors.black87,
    );
  }

  // TEXT FIELD - Uniform style with flexible width
  Widget _buildTextField(String fieldId, String label, dynamic value) {
    // Get or create controller
    final controller = _controllers[fieldId];
    
    return IntrinsicWidth(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 80,
          maxWidth: 200,
        ),
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: _getFieldDecoration(),
          alignment: Alignment.centerLeft,
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: label,
              hintStyle: _getFieldTextStyle(color: Colors.grey[400]),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            style: _getFieldTextStyle(),
            onChanged: (newValue) {
              _handleEmbeddedFieldChange(fieldId, newValue);
            },
          ),
        ),
      ),
    );
  }

  // NUMBER FIELD - Uniform style
  Widget _buildNumberField(String fieldId, String label, dynamic value) {
    // Get or create controller
    final controller = _controllers[fieldId];
    
    return Container(
      width: 100,
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: _getFieldDecoration(),
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: _getFieldTextStyle(color: Colors.grey[400]),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        style: _getFieldTextStyle(),
        keyboardType: TextInputType.number,
        onChanged: (newValue) {
          final numValue = int.tryParse(newValue) ?? double.tryParse(newValue);
          _handleEmbeddedFieldChange(fieldId, numValue ?? newValue);
        },
      ),
    );
  }

  // DATE FIELD - Uniform style with icon and local state
  Widget _buildDateField(String fieldId, String label, dynamic value) {
    // Parse current value to DateTime if it exists
    DateTime? selectedDate;
    if (value != null && value.toString().isNotEmpty) {
      try {
        selectedDate = DateTime.parse(value.toString());
      } catch (e) {
        selectedDate = null;
      }
    }

    // Format display text
    String displayText;
    if (selectedDate != null) {
      displayText = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
    } else {
      displayText = label;
    }

    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Colors.blue,
                  onPrimary: Colors.white,
                ),
              ),
              child: child!,
            );
          },
        );
        if (date != null) {
          final formattedDate = date.toIso8601String().split('T')[0];
          setState(() {
            _fieldValues[fieldId] = formattedDate;
          });
          _handleEmbeddedFieldChange(fieldId, formattedDate);
        }
      },
      borderRadius: BorderRadius.circular(4),
      child: IntrinsicWidth(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 100,
            maxWidth: 150,
          ),
          child: Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: _getFieldDecoration(),
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    displayText,
                    style: _getFieldTextStyle(
                      color: selectedDate == null ? Colors.grey[400] : Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // SELECT FIELD - Uniform style
  Widget _buildSelectField(String fieldId, String label, dynamic value) {
    return Container(
      width: 150,
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: _getFieldDecoration(),
      alignment: Alignment.centerLeft,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value?.toString(),
          hint: Text(
            label,
            style: _getFieldTextStyle(color: Colors.grey[400]),
            overflow: TextOverflow.ellipsis,
          ),
          isDense: true,
          isExpanded: true,
          style: _getFieldTextStyle(),
          icon: Icon(Icons.arrow_drop_down, size: 18, color: Colors.grey[600]),
          dropdownColor: Colors.white,
          elevation: 8,
          menuMaxHeight: 200,
          items: ['Option 1', 'Option 2', 'Option 3']
              .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
              .toList(),
          onChanged: (newValue) => _handleEmbeddedFieldChange(fieldId, newValue),
        ),
      ),
    );
  }

  // CHECKBOX FIELD - Uniform style
  Widget _buildCheckboxField(String fieldId, String label, dynamic value) {
    final isChecked = value == true || value == 'true';
    
    return InkWell(
      onTap: () => _handleEmbeddedFieldChange(fieldId, !isChecked),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: _getFieldDecoration(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: Checkbox(
                value: isChecked,
                onChanged: (newValue) => _handleEmbeddedFieldChange(fieldId, newValue),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                side: BorderSide(color: Colors.grey[400]!, width: 1.5),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: _getFieldTextStyle(),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper class to identify text segments
class _TextSegment {
  final String text;
  _TextSegment(this.text);
}
