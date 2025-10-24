import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NumberFieldRenderer extends StatefulWidget {
  final String fieldId;
  final Map<String, dynamic> fieldSchema;
  final Map<String, dynamic> uiSchema;
  final bool isRequired;
  final dynamic value;
  final bool readOnly;
  final Function(dynamic) onChanged;
  final FocusNode? focusNode;

  const NumberFieldRenderer({
    Key? key,
    required this.fieldId,
    required this.fieldSchema,
    required this.uiSchema,
    required this.isRequired,
    required this.value,
    required this.readOnly,
    required this.onChanged,
    this.focusNode,
  }) : super(key: key);

  @override
  State<NumberFieldRenderer> createState() => _NumberFieldRendererState();
}

class _NumberFieldRendererState extends State<NumberFieldRenderer> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(NumberFieldRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value?.toString() != _controller.text) {
      _controller.text = widget.value?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.fieldSchema['title'] as String? ?? widget.fieldId;
    final description = widget.fieldSchema['description'] as String?;
    final placeholder = widget.uiSchema['ui:placeholder'] as String?;
    final minimum = widget.fieldSchema['minimum'] as num?;
    final maximum = widget.fieldSchema['maximum'] as num?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(title),
        const SizedBox(height: 8),
        TextFormField(
          controller: _controller,
          focusNode: widget.focusNode,
          readOnly: widget.readOnly,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\-?\d*\.?\d*')),
          ],
          decoration: InputDecoration(
            hintText: placeholder ?? 'Enter $title',
            helperText: description,
            helperMaxLines: 2,
            suffixText: _getSuffixText(),
            filled: true,
            fillColor: widget.readOnly ? Colors.grey[100] : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF1976d2), width: 2),
            ),
          ),
          validator: (value) => _validate(value),
          onChanged: (value) {
            if (value.isEmpty) {
              widget.onChanged(null);
            } else {
              final numValue = num.tryParse(value);
              widget.onChanged(numValue);
            }
          },
        ),
      ],
    );
  }

  Widget _buildLabel(String title) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2c3e50),
        ),
        children: [
          TextSpan(text: title),
          if (widget.isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.red),
            ),
        ],
      ),
    );
  }

  String? _getSuffixText() {
    final minimum = widget.fieldSchema['minimum'] as num?;
    final maximum = widget.fieldSchema['maximum'] as num?;
    
    if (minimum != null && maximum != null) {
      return '($minimum-$maximum)';
    } else if (minimum != null) {
      return '(min: $minimum)';
    } else if (maximum != null) {
      return '(max: $maximum)';
    }
    return null;
  }

  String? _validate(String? value) {
    final title = widget.fieldSchema['title'] as String? ?? widget.fieldId;
    
    if (widget.isRequired && (value == null || value.trim().isEmpty)) {
      return '$title is required';
    }
    
    if (value == null || value.isEmpty) {
      return null;
    }
    
    final numValue = num.tryParse(value);
    if (numValue == null) {
      return 'Please enter a valid number';
    }
    
    final minimum = widget.fieldSchema['minimum'] as num?;
    if (minimum != null && numValue < minimum) {
      return '$title must be at least $minimum';
    }
    
    final maximum = widget.fieldSchema['maximum'] as num?;
    if (maximum != null && numValue > maximum) {
      return '$title must be no more than $maximum';
    }
    
    return null;
  }
}
