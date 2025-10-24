import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/form_builder/form_field.dart' as form_models;

/// Preview Date Field - Functional date picker field with internal state
class PreviewDateField extends StatefulWidget {
  final form_models.FormField field;
  final dynamic value;
  final Function(dynamic) onChanged;
  final bool hasError;

  const PreviewDateField({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
    this.hasError = false,
  });

  @override
  State<PreviewDateField> createState() => _PreviewDateFieldState();
}

class _PreviewDateFieldState extends State<PreviewDateField> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _initializeDate();
  }

  void _initializeDate() {
    if (widget.value != null) {
      if (widget.value is DateTime) {
        _selectedDate = widget.value;
      } else if (widget.value is String && widget.value.isNotEmpty) {
        try {
          _selectedDate = DateTime.parse(widget.value);
        } catch (e) {
          _selectedDate = null;
        }
      }
    }
  }

  @override
  void didUpdateWidget(PreviewDateField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update if value changed externally (e.g., form reset)
    if (widget.value != oldWidget.value) {
      _initializeDate();
    }
  }
 
  @override
  Widget build(BuildContext context) {
    final dateText = _selectedDate != null
        ? DateFormat('MMM dd, yyyy').format(_selectedDate!)
        : '';

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

        // Date Picker Button
        InkWell(
          onTap: () => _selectDate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: widget.hasError ? Colors.red : Colors.grey[300]!,
              ),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    dateText.isEmpty ? 'Select date' : dateText,
                    style: TextStyle(
                      fontSize: 14,
                      color: dateText.isEmpty ? Colors.grey[600] : Colors.black87,
                    ),
                  ),
                ),
                if (dateText.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      setState(() {
                        _selectedDate = null;
                      });
                      widget.onChanged('');
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      // Format date as YYYY-MM-DD for backend compatibility
      final formattedDate = DateFormat('yyyy-MM-dd').format(picked);
      debugPrint('📅 Date selected: $formattedDate');
      widget.onChanged(formattedDate);
    }
  }
}
