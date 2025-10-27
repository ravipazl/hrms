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
      children: content.map((e) => _buildElement(e as Map<String, dynamic>)).toList(),
    );
  }

  Widget _buildElement(Map<String, dynamic> element) {
    final type = element['type'] as String?;
    final children = element['children'] as List<dynamic>? ?? [];

    String text = '';
    Map<String, dynamic> styling = {};
    
    for (var child in children) {
      if (child is Map<String, dynamic> && child.containsKey('text')) {
        text = child['text'] as String;
        styling = child;
        break;
      }
    }

    if (text.isEmpty) return const SizedBox.shrink();

    final style = _getStyle(type, styling);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _buildInlineContent(text, style),
    );
  }

  /// Build content with ALL fields using RichText for proper inline layout
  Widget _buildInlineContent(String text, TextStyle style) {
    final pattern = RegExp(r'\[(.*?)\]');
    final matches = pattern.allMatches(text);

    if (matches.isEmpty) {
      return Text(text, style: style);
    }

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

    return RichText(
      text: TextSpan(children: spans),
    );
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

  TextStyle _getStyle(String? type, Map<String, dynamic> styling) {
    TextStyle base;
    
    switch (type) {
      case 'heading-one':
      case 'h1':
        base = const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.3, color: Colors.black87);
        break;
      case 'heading-two':
      case 'h2':
        base = const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.3, color: Colors.black87);
        break;
      case 'heading-three':
      case 'h3':
        base = const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.3, color: Colors.black87);
        break;
      default:
        base = const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87);
    }

    if (styling['bold'] == true) base = base.copyWith(fontWeight: FontWeight.bold);
    if (styling['italic'] == true) base = base.copyWith(fontStyle: FontStyle.italic);
    if (styling['underline'] == true) base = base.copyWith(decoration: TextDecoration.underline);

    return base;
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


