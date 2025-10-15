import 'package:flutter/material.dart';
import '../../../../models/form_builder/form_field.dart' as form_models;

/// Preview Checkbox Field - Single checkbox field
class PreviewCheckboxField extends StatelessWidget {
  final form_models.FormField field;
  final dynamic value;
  final Function(dynamic) onChanged;
  final bool hasError;
 
  const PreviewCheckboxField({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure value is boolean - handle null/undefined cases
    final isChecked = value == true;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: hasError ? Colors.red : Colors.grey[300]!,
        ),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: CheckboxListTile(
        title: Row(
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
        value: isChecked,
        onChanged: (newValue) {
          debugPrint('Checkbox ${field.id} changed from $value to ${newValue ?? false}');
          onChanged(newValue ?? false);
        },
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
}
