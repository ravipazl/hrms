import 'package:flutter/material.dart';
import '../../../../models/form_builder/form_field.dart' as form_models;

/// Preview TextArea Field - Functional multiline text input field
/// COMPLETELY RECONSTRUCTED: Proper controller lifecycle management
class PreviewTextAreaField extends StatefulWidget {
  final form_models.FormField field;
  final dynamic value;
  final Function(dynamic) onChanged;
  final bool hasError;

  const PreviewTextAreaField({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
    this.hasError = false,
  });

  @override
  State<PreviewTextAreaField> createState() => _PreviewTextAreaFieldState();
}

class _PreviewTextAreaFieldState extends State<PreviewTextAreaField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isInternalUpdate = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controller = TextEditingController(text: widget.value?.toString() ?? '');
    
    // Add listener to detect changes
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    // Only call onChanged if the change came from user input
    if (!_isInternalUpdate) {
      widget.onChanged(_controller.text);
    }
  }

  @override
  void didUpdateWidget(PreviewTextAreaField oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Only update controller text if:
    // 1. The value prop changed from parent
    // 2. The new value is different from current controller text
    // 3. The field is not currently focused (user is not typing)
    final newValue = widget.value?.toString() ?? '';
    if (widget.value != oldWidget.value && 
        newValue != _controller.text &&
        !_focusNode.hasFocus) {
      _isInternalUpdate = true;
      _controller.text = newValue;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: newValue.length),
      );
      _isInternalUpdate = false;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rows = widget.field.props['rows'] is int ? widget.field.props['rows'] as int : 4;
    final maxLength = widget.field.props['maxLength'] is int ? widget.field.props['maxLength'] as int : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // TextArea Input
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          maxLines: rows,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: widget.field.placeholder ?? 'Enter text...',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: widget.hasError ? Colors.red : Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: widget.hasError ? Colors.red : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: widget.hasError ? Colors.red : Colors.blue,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }
}
