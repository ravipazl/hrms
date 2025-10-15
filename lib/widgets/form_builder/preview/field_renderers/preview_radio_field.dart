import 'package:flutter/material.dart';
import '../../../../models/form_builder/form_field.dart' as form_models;

/// Preview Radio Field - Functional radio buttons field
class PreviewRadioField extends StatelessWidget {
  final form_models.FormField field;
  final dynamic value;
  final Function(dynamic) onChanged;
  final bool hasError;

  const PreviewRadioField({
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

        // Radio Options
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: hasError ? Colors.red : Colors.grey[300]!,
            ),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: Column(
            children: options.map((option) {
              return RadioListTile<String>(
                title: Text(option),
                value: option,
                groupValue: selectedValue,
                onChanged: (newValue) {
                  if (newValue != null) {
                    debugPrint('Radio ${field.id} changed from "$selectedValue" to "$newValue"');
                    onChanged(newValue);
                  }
                },
                contentPadding: EdgeInsets.zero,
                dense: true,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
