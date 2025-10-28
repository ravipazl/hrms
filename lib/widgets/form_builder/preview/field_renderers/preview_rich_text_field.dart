import 'package:flutter/material.dart';
import '../../../../models/form_builder/form_field.dart' as form_models;

/// BRAND NEW IMPLEMENTATION - Completely rewritten from scratch
/// Uses a different architecture: Stack-based absolute positioning
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
  final Map<String, GlobalKey> _fieldKeys = {};

  @override
  void initState() {
    super.initState();
    _setup();
  }

  void _setup() {
    _embeddedFields = (widget.field.props['embeddedFields'] as List<dynamic>?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        [];

    if (widget.value is Map) {
      final valueMap = widget.value as Map<String, dynamic>;
      _fieldValues = Map<String, dynamic>.from(
        valueMap['embeddedFieldValues'] as Map? ?? {}
      );
    }

    for (var field in _embeddedFields) {
      final fieldId = field['id'] as String;
      final fieldType = field['fieldType'] as String;
      
      _fieldKeys[fieldId] = GlobalKey();
      
      if (fieldType == 'text' || fieldType == 'email' || 
          fieldType == 'url' || fieldType == 'tel' || fieldType == 'number') {
        _controllers[fieldId] = TextEditingController(
          text: _fieldValues[fieldId]?.toString() ?? ''
        );
      }
    }

    _notifyParent();
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateField(String fieldId, dynamic value, {bool rebuild = false}) {
    if (rebuild) {
      setState(() => _fieldValues[fieldId] = value);
    } else {
      _fieldValues[fieldId] = value;
    }
    _notifyParent();
  }

  void _notifyParent() {
    widget.onChanged({
      'content': widget.field.props['content'] ?? [],
      'embeddedFields': widget.field.props['embeddedFields'] ?? [],
      'embeddedFieldValues': Map<String, dynamic>.from(_fieldValues),
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.field.props['content'] as List<dynamic>? ?? [];
    if (content.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _buildContentWithListTracking(content),
    );
  }

  /// Build content while tracking list indices for numbered lists
  List<Widget> _buildContentWithListTracking(List<dynamic> content) {
    final widgets = <Widget>[];
    int orderedListIndex = 0;
    String? lastListType;

    for (var element in content) {
      if (element is! Map<String, dynamic>) continue;

      final type = element['type'] as String?;

      // Track list indices
      if (type == 'numbered-list' || type == 'ordered-list') {
        if (lastListType != 'ordered') {
          orderedListIndex = 1; // Reset for new list
        } else {
          orderedListIndex++;
        }
        lastListType = 'ordered';
        widgets.add(_buildListElement(element, orderedListIndex));
      } else if (type == 'bulleted-list' || type == 'unordered-list') {
        lastListType = 'unordered';
        widgets.add(_buildListElement(element, null));
      } else {
        lastListType = null;
        orderedListIndex = 0;
        widgets.add(_buildElement(element));
      }
    }

    return widgets;
  }

  /// Build list item (bullet or numbered)
  Widget _buildListElement(Map<String, dynamic> element, int? number) {
    final children = element['children'] as List<dynamic>? ?? [];
    if (children.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bullet or number
          SizedBox(
            width: 24,
            child: Text(
              number != null ? '$number.' : '•',
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Content
          Expanded(
            child: _buildStyledContent(children, element['type'] as String?),
          ),
        ],
      ),
    );
  }

  Widget _buildElement(Map<String, dynamic> element) {
    final type = element['type'] as String?;
    final children = element['children'] as List<dynamic>? ?? [];

    if (children.isEmpty) return const SizedBox.shrink();

    // Get alignment from element
    final alignment = _getAlignment(element);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: alignment,
        child: _buildStyledContent(children, type),
      ),
    );
  }

  /// Get text alignment from element properties
  Alignment _getAlignment(Map<String, dynamic> element) {
    final align = element['align'] as String?;
    switch (align) {
      case 'left':
        return Alignment.centerLeft;
      case 'center':
        return Alignment.center;
      case 'right':
        return Alignment.centerRight;
      case 'justify':
        return Alignment.centerLeft;
      default:
        return Alignment.centerLeft;
    }
  }

  /// Build content with proper styling from children
  Widget _buildStyledContent(List<dynamic> children, String? elementType) {
    final spans = <InlineSpan>[];

    for (var child in children) {
      if (child is! Map<String, dynamic>) continue;

      final text = child['text'] as String? ?? '';
      if (text.isEmpty) continue;

      // Get base style from element type
      final baseStyle = _getBaseStyle(elementType);
      
      // Apply inline styling (bold, italic, underline)
      final style = _applyInlineStyling(baseStyle, child);

      // Check if text contains embedded fields
      final pattern = RegExp(r'\[(.*?)\]');
      final matches = pattern.allMatches(text);

      if (matches.isEmpty) {
        // No fields, just add styled text
        spans.add(TextSpan(text: text, style: style));
      } else {
        // Has fields, process them
        spans.addAll(_processTextWithFields(text, style, matches));
      }
    }

    if (spans.isEmpty) {
      return const SizedBox.shrink();
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  /// Process text that contains embedded fields
  List<InlineSpan> _processTextWithFields(
    String text,
    TextStyle style,
    Iterable<RegExpMatch> matches,
  ) {
    final spans = <InlineSpan>[];
    int lastIndex = 0;

    for (final match in matches) {
      // Add text before the field
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: style,
        ));
      }

      // Find and add the field widget
      final label = match.group(1) ?? '';
      final field = _findField(label);
      
      if (field != null) {
        final fieldId = field['id'] as String;
        final fieldType = field['fieldType'] as String;
        
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: _createField(fieldId, fieldType, label),
        ));
      } else {
        // Field not found, show as text
        spans.add(TextSpan(
          text: match.group(0),
          style: style,
        ));
      }

      lastIndex = match.end;
    }

    // Add remaining text after last field
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: style,
      ));
    }

    return spans;
  }

  /// Get base text style from element type (h1, h2, paragraph, etc.)
  TextStyle _getBaseStyle(String? type) {
    switch (type) {
      case 'heading-one':
      case 'h1':
        return const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          height: 1.2,
          color: Colors.black87,
        );
      case 'heading-two':
      case 'h2':
        return const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          height: 1.3,
          color: Colors.black87,
        );
      case 'heading-three':
      case 'h3':
        return const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.3,
          color: Colors.black87,
        );
      case 'heading-four':
      case 'h4':
        return const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.4,
          color: Colors.black87,
        );
      case 'heading-five':
      case 'h5':
        return const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.4,
          color: Colors.black87,
        );
      case 'heading-six':
      case 'h6':
        return const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.4,
          color: Colors.black87,
        );
      default:
        return const TextStyle(
          fontSize: 14,
          height: 1.5,
          color: Colors.black87,
        );
    }
  }

  /// Apply inline styling (bold, italic, underline, strikethrough, etc.) from child properties
  TextStyle _applyInlineStyling(TextStyle base, Map<String, dynamic> child) {
    TextStyle result = base;

    // Bold
    if (child['bold'] == true) {
      result = result.copyWith(fontWeight: FontWeight.bold);
    }
    
    // Italic
    if (child['italic'] == true) {
      result = result.copyWith(fontStyle: FontStyle.italic);
    }
    
    // Underline
    if (child['underline'] == true) {
      result = result.copyWith(decoration: TextDecoration.underline);
    }

    // Strikethrough
    if (child['strikethrough'] == true || child['strike'] == true) {
      result = result.copyWith(decoration: TextDecoration.lineThrough);
    }

    // Text Color
    if (child['color'] != null) {
      final colorValue = child['color'];
      Color? textColor;
      
      if (colorValue is String) {
        // Handle hex color: #FF5733 or FF5733
        try {
          final hex = colorValue.replaceAll('#', '');
          textColor = Color(int.parse('FF$hex', radix: 16));
        } catch (_) {
          // Handle named colors
          textColor = _getNamedColor(colorValue);
        }
      } else if (colorValue is int) {
        textColor = Color(colorValue);
      }
      
      if (textColor != null) {
        result = result.copyWith(color: textColor);
      }
    }

    // Background Color
    if (child['backgroundColor'] != null || child['background'] != null) {
      final bgValue = child['backgroundColor'] ?? child['background'];
      Color? bgColor;
      
      if (bgValue is String) {
        try {
          final hex = bgValue.replaceAll('#', '');
          bgColor = Color(int.parse('FF$hex', radix: 16));
        } catch (_) {
          bgColor = _getNamedColor(bgValue);
        }
      } else if (bgValue is int) {
        bgColor = Color(bgValue);
      }
      
      if (bgColor != null) {
        result = result.copyWith(backgroundColor: bgColor);
      }
    }

    // Font Size
    if (child['fontSize'] != null) {
      final size = child['fontSize'];
      if (size is num) {
        result = result.copyWith(fontSize: size.toDouble());
      }
    }

    return result;
  }

  /// Get color from named color strings
  Color? _getNamedColor(String colorName) {
    final name = colorName.toLowerCase();
    switch (name) {
      case 'red': return Colors.red;
      case 'blue': return Colors.blue;
      case 'green': return Colors.green;
      case 'yellow': return Colors.yellow;
      case 'orange': return Colors.orange;
      case 'purple': return Colors.purple;
      case 'pink': return Colors.pink;
      case 'teal': return Colors.teal;
      case 'cyan': return Colors.cyan;
      case 'indigo': return Colors.indigo;
      case 'lime': return Colors.lime;
      case 'amber': return Colors.amber;
      case 'brown': return Colors.brown;
      case 'grey': case 'gray': return Colors.grey;
      case 'black': return Colors.black;
      case 'white': return Colors.white;
      default: return null;
    }
  }


  Map<String, dynamic>? _findField(String label) {
    for (var field in _embeddedFields) {
      if (field['label'] == label) {
        return field;
      }
    }
    return null;
  }

  Widget _createField(String id, String type, String label) {
    switch (type) {
      case 'text':
      case 'email':
      case 'url':
      case 'tel':
        return _textField(id, label);
      case 'number':
        return _numberField(id, label);
      case 'date':
        return _dateField(id, label, _fieldValues[id]);
      case 'select':
        return _selectField(id, label, _fieldValues[id]);
      case 'checkbox':
        return _checkboxField(id, label, _fieldValues[id]);
      default:
        return _textField(id, label);
    }
  }


  Widget _textField(String id, String label) {
    return Container(
      height: 24,
      constraints: const BoxConstraints(minWidth: 80, maxWidth: 200),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF90CAF9), width: 1),
        borderRadius: BorderRadius.circular(4),
        color: Colors.white,
      ),
      child: TextField(
        controller: _controllers[id],
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        onChanged: (v) => _updateField(id, v),
      ),
    );
  }

  Widget _numberField(String id, String label) {
    return Container(
      height: 24,
      constraints: const BoxConstraints(minWidth: 60, maxWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF90CAF9), width: 1),
        borderRadius: BorderRadius.circular(4),
        color: Colors.white,
      ),
      child: TextField(
        controller: _controllers[id],
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        onChanged: (v) {
          final num = int.tryParse(v) ?? double.tryParse(v);
          _updateField(id, num ?? v);
        },
      ),
    );
  }

  Widget _dateField(String id, String label, dynamic value) {
    DateTime? date;
    if (value != null) {
      try { date = DateTime.parse(value.toString()); } catch (_) {}
    }

    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          _updateField(id, picked.toIso8601String().split('T')[0], rebuild: true);
        }
      },
      child: Container(
        height: 24,
        constraints: const BoxConstraints(minWidth: 100, maxWidth: 150),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF90CAF9), width: 1),
          borderRadius: BorderRadius.circular(4),
          color: Colors.white,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              date != null
                  ? '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
                  : label,
              style: TextStyle(
                fontSize: 14,
                color: date == null ? Colors.grey : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectField(String id, String label, dynamic value) {
    return Container(
      height: 24,
      constraints: const BoxConstraints(minWidth: 100, maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF90CAF9), width: 1),
        borderRadius: BorderRadius.circular(4),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value?.toString(),
          hint: Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          isDense: true,
          isExpanded: true,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          icon: const Icon(Icons.arrow_drop_down, size: 16),
          items: ['Option 1', 'Option 2', 'Option 3']
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: (v) => _updateField(id, v, rebuild: true),
        ),
      ),
    );
  }

  Widget _checkboxField(String id, String label, dynamic value) {
    final checked = value == true || value == 'true';
    
    return GestureDetector(
      onTap: () => _updateField(id, !checked, rebuild: true),
      child: Container(
        height: 24,
        constraints: const BoxConstraints(minWidth: 80, maxWidth: 150),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF90CAF9), width: 1),
          borderRadius: BorderRadius.circular(4),
          color: Colors.white,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: Checkbox(
                value: checked,
                onChanged: (v) => _updateField(id, v ?? false, rebuild: true),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}


