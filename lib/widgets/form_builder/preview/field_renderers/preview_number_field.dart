import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../models/form_builder/form_field.dart' as form_models;

/// Preview Number Field - Functional number input field
/// COMPLETELY RECONSTRUCTED: Proper controller lifecycle management
class PreviewNumberField extends StatefulWidget {
  final form_models.FormField field;
  final dynamic value;
  final Function(dynamic) onChanged;
  final bool hasError;
 
  const PreviewNumberField({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
    this.hasError = false,
  });

  @override
  State<PreviewNumberField> createState() => _PreviewNumberFieldState();
}

class _PreviewNumberFieldState extends State<PreviewNumberField> {
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
      // Parse the number value
      final text = _controller.text;
      if (text.isEmpty) {
        widget.onChanged(null);
      } else {
        final numValue = num.tryParse(text);
        widget.onChanged(numValue ?? text);
      }
    }
  }

  @override
  void didUpdateWidget(PreviewNumberField oldWidget) {
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
    final min = widget.field.props['min'];
    final max = widget.field.props['max'];
    final step = widget.field.props['step'] ?? 1;

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

        // Number Input
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.-]')),
          ],
          decoration: InputDecoration(
            hintText: widget.field.placeholder ?? 'Enter number...',
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
            helperText: _getHelperText(min, max, step),
            helperStyle: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  String? _getHelperText(dynamic min, dynamic max, dynamic step) {
    final minVal = min is num ? min : null;
    final maxVal = max is num ? max : null;
    final stepVal = step is num ? step : null;
    
    if (minVal != null && maxVal != null) {
      return 'Range: $minVal to $maxVal (step: ${stepVal ?? 1})';
    } else if (minVal != null) {
      return 'Minimum: $minVal';
    } else if (maxVal != null) {
      return 'Maximum: $maxVal';
    }
    return stepVal != null ? 'Step: $stepVal' : null;
  }
}
