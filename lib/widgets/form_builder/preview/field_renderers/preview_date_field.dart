import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/form_builder/form_field.dart' as form_models;

/// Preview Date Field - Functional date picker field
class PreviewDateField extends StatelessWidget {
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
  Widget build(BuildContext context) {
    DateTime? selectedDate;
    
    if (value != null) {
      if (value is DateTime) {
        selectedDate = value;
      } else if (value is String && value.isNotEmpty) {
        try {
          selectedDate = DateTime.parse(value);
        } catch (e) {
          selectedDate = null;
        }
      }
    }

    final dateText = selectedDate != null
        ? DateFormat('MMM dd, yyyy').format(selectedDate)
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          children: [
            Text(
              field.label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (field.required)
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
                color: hasError ? Colors.red : Colors.grey[300]!,
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
                    onPressed: () => onChanged(''),
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
      initialDate: value is DateTime 
          ? value 
          : (value is String && value.isNotEmpty)
              ? DateTime.tryParse(value) ?? DateTime.now()
              : DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      // ✅ Format date as YYYY-MM-DD for backend compatibility
      final formattedDate = DateFormat('yyyy-MM-dd').format(picked);
      debugPrint('📅 Date selected: $formattedDate');
      onChanged(formattedDate);
    }
  }
}
