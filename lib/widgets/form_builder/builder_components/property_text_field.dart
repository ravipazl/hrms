import 'package:flutter/material.dart';
import 'dart:async';
 
/// Stateful Text Field for Properties Panel
/// Prevents cursor reset issues by maintaining controller state
class PropertyTextField extends StatefulWidget {
  final String? initialValue;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final TextInputType? keyboardType;
  final int? maxLines;
  final Function(String) onChanged;
  final InputDecoration? decoration;

  const PropertyTextField({
    super.key,
    this.initialValue,
    this.labelText,
    this.hintText,
    this.helperText,
    this.keyboardType,
    this.maxLines,
    required this.onChanged,
    this.decoration,
  });

  @override
  State<PropertyTextField> createState() => _PropertyTextFieldState();
}

class _PropertyTextFieldState extends State<PropertyTextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isInternalUpdate = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controller = TextEditingController(text: widget.initialValue ?? '');
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (!_isInternalUpdate) {
      // Debounce the updates to prevent excessive rebuilds
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () {
        widget.onChanged(_controller.text);
      });
    }
  }

  @override
  void didUpdateWidget(PropertyTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    final newValue = widget.initialValue ?? '';
    
    // Only update if:
    // 1. Initial value actually changed
    // 2. Controller text doesn't match new value
    // 3. Field is NOT focused (user not typing)
    if (widget.initialValue != oldWidget.initialValue && 
        newValue != _controller.text &&
        !_focusNode.hasFocus) {
      
      _isInternalUpdate = true;
      
      // Preserve cursor position when possible
      final cursorPosition = _controller.selection.baseOffset;
      _controller.text = newValue;
      
      // Restore cursor to valid position
      final newCursorPosition = cursorPosition.clamp(0, newValue.length);
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: newCursorPosition),
      );
      
      _isInternalUpdate = false;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      keyboardType: widget.keyboardType,
      maxLines: widget.maxLines ?? 1,
      decoration: widget.decoration ??
          InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            helperText: widget.helperText,
            border: const OutlineInputBorder(),
          ),
    );
  }
}
