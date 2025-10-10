import 'package:flutter/material.dart';
import '../../../../models/form_builder/form_field.dart' as form_models;

/// Preview Select Field - Functional dropdown select field
class PreviewSelectField extends StatelessWidget {
  final form_models.FormField field;
  final dynamic value;
  final Function(dynamic) onChanged;
  final bool hasError;

  const PreviewSelectField({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    // Safely extract options
    List<String> options = [];
    final optionsList = field.props['options'];
    if (optionsList is List) {
      options = optionsList.map((e) => e.toString()).toList();
    }
    
    final selectedValue = value?.toString();

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

        // Dropdown
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: hasError ? Colors.red : Colors.grey[300]!,
            ),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: DropdownButtonFormField<String>(
            initialValue: options.contains(selectedValue) ? selectedValue : null,
            decoration: InputDecoration(
              hintText: 'Select an option',
              filled: true,
              fillColor: Colors.white,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            items: options.map((option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              );
            }).toList(),
            onChanged: (newValue) {
              if (newValue != null) {
                onChanged(newValue);
              }
            },
            icon: const Icon(Icons.arrow_drop_down),
            isExpanded: true,
          ),
        ),
      ],
    );
  }
}
