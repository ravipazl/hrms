import 'package:flutter/material.dart';
import '../../../../models/form_builder/form_field.dart' as form_models;

/// Rich Text Field Renderer for Form Preview (Preview/Submission Mode)
/// Hybrid approach: Wrap for layout + proper interaction handling
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

  @override
  void initState() {
    super.initState();
    _initializeEmbeddedFields();
    _initializeValues();
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

  void _handleEmbeddedFieldChange(String fieldId, dynamic value) {
    setState(() {
      _fieldValues[fieldId] = value;
    });
    widget.onChanged(_fieldValues);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: widget.hasError ? Colors.red : Colors.grey[300]!,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rich text label
          Row(
            children: [
              Icon(Icons.text_fields, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                widget.field.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              if (widget.field.required)
                const Text(
                  ' *',
                  style: TextStyle(color: Colors.red, fontSize: 13),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Rich text content
          _buildRichTextContent(),
        ],
      ),
    );
  }

  Widget _buildRichTextContent() {
    final slateContent = widget.field.props['content'] as List<dynamic>? ?? [];

    if (slateContent.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: const Text(
          'No content',
          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: slateContent.map((element) {
          return _buildSlateElement(element as Map<String, dynamic>);
        }).toList(),
      ),
    );
  }

  Widget _buildSlateElement(Map<String, dynamic> element) {
    final type = element['type'] as String?;
    final children = element['children'] as List<dynamic>? ?? [];

    // Get base text style for this element type
    final baseStyle = _getTextStyleForType(type);

    // Build inline widgets (text + interactive fields)
    final inlineWidgets = _buildInlineWidgets(children, baseStyle);

    // Use Wrap for proper inline flow with full interactivity
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 0,
        runSpacing: 0,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: inlineWidgets,
      ),
    );
  }

  TextStyle _getTextStyleForType(String? type) {
    switch (type) {
      case 'heading-one':
        return const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          height: 1.3,
          color: Colors.black87,
        );
      case 'heading-two':
        return const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          height: 1.3,
          color: Colors.black87,
        );
      case 'heading-three':
        return const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          height: 1.3,
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

  List<Widget> _buildInlineWidgets(
    List<dynamic> children,
    TextStyle baseStyle,
  ) {
    final List<Widget> widgets = [];

    for (var child in children) {
      if (child is Map<String, dynamic> && child.containsKey('text')) {
        final text = child['text'] as String;

        // Check if text contains embedded field markers
        if (_containsEmbeddedFieldMarker(text)) {
          // Parse text with embedded fields
          widgets.addAll(_parseTextWithEmbeddedFields(text, child, baseStyle));
        } else if (text.isNotEmpty) {
          // Regular text widget - wrapped in Padding for spacing
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(right: 1),
              child: _createInlineTextWidget(text, child, baseStyle),
            ),
          );
        }
      }
    }

    return widgets;
  }

  bool _containsEmbeddedFieldMarker(String text) {
    final emojiPattern = RegExp(r'[📝🔢📧📅📋☑️🔘📄📌]\s*\[.*?\]');
    return emojiPattern.hasMatch(text);
  }

  List<Widget> _parseTextWithEmbeddedFields(
    String text,
    Map<String, dynamic> styling,
    TextStyle baseStyle,
  ) {
    final List<Widget> widgets = [];
    final emojiPattern = RegExp(r'([📝🔢📧📅📋☑️🔘📄📌])\s*\[(.*?)\]\s*');

    int lastMatchEnd = 0;
    final matches = emojiPattern.allMatches(text);

    for (var match in matches) {
      // Add text BEFORE the match
      if (match.start > lastMatchEnd) {
        final beforeText = text.substring(lastMatchEnd, match.start);
        if (beforeText.isNotEmpty) {
          widgets.add(_createInlineTextWidget(beforeText, styling, baseStyle));
        }
      }

      // Add embedded field
      final label = match.group(2) ?? '';
      final embeddedField = _findEmbeddedFieldByLabel(label);

      if (embeddedField != null) {
        final fieldId = embeddedField['id'] as String;
        final fieldType = embeddedField['fieldType'] as String;
        final currentValue = _fieldValues[fieldId];

        // Add interactive field as a regular widget (NOT in WidgetSpan)
        widgets.add(
          _buildInteractiveField(fieldId, fieldType, label, currentValue),
        );
      } else {
        // Field not found - show as text
        final emoji = match.group(1) ?? '';
        widgets.add(_createInlineTextWidget('$emoji [$label]', styling, baseStyle));
      }

      lastMatchEnd = match.end;
    }

    // Add REMAINING text after all matches
    if (lastMatchEnd < text.length) {
      final remainingText = text.substring(lastMatchEnd);
      if (remainingText.isNotEmpty) {
        widgets.add(_createInlineTextWidget(remainingText, styling, baseStyle));
      }
    }

    return widgets;
  }

  Map<String, dynamic>? _findEmbeddedFieldByLabel(String label) {
    for (var field in _embeddedFields) {
      if (field['label'] == label) {
        return field;
      }
    }
    return null;
  }

  Widget _createInlineTextWidget(
    String text,
    Map<String, dynamic> styling,
    TextStyle baseStyle,
  ) {
    TextStyle style = baseStyle;

    // Apply inline formatting
    if (styling['bold'] == true) {
      style = style.copyWith(fontWeight: FontWeight.bold);
    }
    if (styling['italic'] == true) {
      style = style.copyWith(fontStyle: FontStyle.italic);
    }
    if (styling['underline'] == true) {
      style = style.copyWith(decoration: TextDecoration.underline);
    }
    if (styling['strike'] == true) {
      style = style.copyWith(decoration: TextDecoration.lineThrough);
    }

    // Return text widget aligned properly
    return Text(text, style: style);
  }

  Widget _buildInteractiveField(
    String fieldId,
    String fieldType,
    String label,
    dynamic currentValue,
  ) {
    // Wrap with minimal padding for inline spacing
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: _buildFieldByType(fieldId, fieldType, label, currentValue),
    );
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

  // ============ FULLY INTERACTIVE FIELD BUILDERS ============

  Widget _buildTextField(String fieldId, String label, dynamic value) {
    return IntrinsicWidth(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 80,
          maxWidth: 180,
        ),
        child: SizedBox(
          height: 32,
          child: TextField(
            controller: TextEditingController(text: value?.toString() ?? ''),
            decoration: InputDecoration(
              hintText: label,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 11),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.blue[300]!, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.blue[300]!, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.blue[600]!, width: 1.5),
              ),
              filled: true,
              fillColor: Colors.blue[50],
            ),
            style: const TextStyle(fontSize: 12, height: 1.0),
            onChanged: (newValue) =>
                _handleEmbeddedFieldChange(fieldId, newValue),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberField(String fieldId, String label, dynamic value) {
    return IntrinsicWidth(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 60,
          maxWidth: 120,
        ),
        child: SizedBox(
          height: 32,
          child: TextField(
            controller: TextEditingController(text: value?.toString() ?? ''),
            decoration: InputDecoration(
              hintText: label,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 11),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.blue[300]!, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.blue[300]!, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.blue[600]!, width: 1.5),
              ),
              filled: true,
              fillColor: Colors.blue[50],
            ),
            style: const TextStyle(fontSize: 12, height: 1.0),
            keyboardType: TextInputType.number,
            onChanged: (newValue) {
              final numValue =
                  int.tryParse(newValue) ?? double.tryParse(newValue);
              _handleEmbeddedFieldChange(fieldId, numValue ?? newValue);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(String fieldId, String label, dynamic value) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
        );
        if (date != null) {
          _handleEmbeddedFieldChange(
            fieldId,
            date.toIso8601String().split('T')[0],
          );
        }
      },
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue[300]!, width: 1),
          borderRadius: BorderRadius.circular(4),
          color: Colors.blue[50],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today, size: 12, color: Colors.blue[700]),
            const SizedBox(width: 4),
            Text(
              value?.toString() ?? label,
              style: TextStyle(
                fontSize: 11,
                height: 1.0,
                color: value == null ? Colors.grey[600] : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectField(String fieldId, String label, dynamic value) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[400]!, width: 1),
        borderRadius: BorderRadius.circular(4),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value?.toString(),
          hint: Text(label, style: const TextStyle(fontSize: 11)),
          isDense: true,
          style: const TextStyle(fontSize: 11, color: Colors.black87, height: 1.0),
          items: ['Option 1', 'Option 2', 'Option 3']
              .map((opt) => DropdownMenuItem(
                    value: opt,
                    child: Text(opt),
                  ))
              .toList(),
          onChanged: (newValue) =>
              _handleEmbeddedFieldChange(fieldId, newValue),
        ),
      ),
    );
  }

  Widget _buildCheckboxField(String fieldId, String label, dynamic value) {
    final isChecked = value == true || value == 'true';
    return InkWell(
      onTap: () => _handleEmbeddedFieldChange(fieldId, !isChecked),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: isChecked,
              onChanged: (newValue) =>
                  _handleEmbeddedFieldChange(fieldId, newValue),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, height: 1.0)),
        ],
      ),
    );
  }
}
