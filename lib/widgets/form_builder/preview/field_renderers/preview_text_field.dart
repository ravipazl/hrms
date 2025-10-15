import 'package:flutter/material.dart';
import '../../../../models/form_builder/form_field.dart' as form_models;

/// Preview Text Field - Functional text input field
/// COMPLETELY RECONSTRUCTED: Proper controller lifecycle management
class PreviewTextField extends StatefulWidget {
  final form_models.FormField field;
  final dynamic value;
  final Function(dynamic) onChanged;
  final bool hasError;

  const PreviewTextField({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
    this.hasError = false,
  });
 
  @override
  State<PreviewTextField> createState() => _PreviewTextFieldState();
}

class _PreviewTextFieldState extends State<PreviewTextField> {
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
  void didUpdateWidget(PreviewTextField oldWidget) {
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
    final maxLength = widget.field.props['maxLength'];
    final minLength = widget.field.props['minLength'];

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

        // Text Input
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          obscureText: widget.field.type == form_models.FieldType.password,
          keyboardType: _getKeyboardType(),
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: widget.field.placeholder ?? 'Enter ${widget.field.label.toLowerCase()}...',
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
            helperText: _getHelperText(minLength, maxLength),
            helperStyle: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ),

        // Character counter for password with strength indicator
        if (widget.field.type == form_models.FieldType.password && 
            widget.field.props['showStrengthIndicator'] == true)
          _buildPasswordStrength(_controller.text),
      ],
    );
  }

  TextInputType _getKeyboardType() {
    switch (widget.field.type) {
      case form_models.FieldType.email:
        return TextInputType.emailAddress;
      case form_models.FieldType.tel:
        return TextInputType.phone;
      case form_models.FieldType.url:
        return TextInputType.url;
      default:
        return TextInputType.text;
    }
  }

  String? _getHelperText(dynamic minLength, dynamic maxLength) {
    final minLen = minLength is int ? minLength : null;
    final maxLen = maxLength is int ? maxLength : null;
    
    if (minLen != null && maxLen != null) {
      return 'Length: $minLen-$maxLen characters';
    } else if (minLen != null) {
      return 'Minimum: $minLen characters';
    } else if (maxLen != null) {
      return 'Maximum: $maxLen characters';
    }
    return null;
  }

  Widget _buildPasswordStrength(String password) {
    final hasUpper = password.contains(RegExp(r'[A-Z]'));
    final hasLower = password.contains(RegExp(r'[a-z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    final strengthCount = [hasUpper, hasLower, hasDigit, hasSpecial]
        .where((x) => x)
        .length;

    String strengthText;
    Color strengthColor;

    if (password.isEmpty) {
      strengthText = '';
      strengthColor = Colors.grey;
    } else if (strengthCount <= 1) {
      strengthText = 'Weak';
      strengthColor = Colors.red;
    } else if (strengthCount == 2) {
      strengthText = 'Fair';
      strengthColor = Colors.orange;
    } else if (strengthCount == 3) {
      strengthText = 'Good';
      strengthColor = Colors.blue;
    } else {
      strengthText = 'Strong';
      strengthColor = Colors.green;
    }

    if (password.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: strengthCount / 4,
                  backgroundColor: Colors.grey[200],
                  color: strengthColor,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                strengthText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: strengthColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Include uppercase, lowercase, numbers, and special characters',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
