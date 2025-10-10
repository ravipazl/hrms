import 'package:flutter/material.dart';
import '../../../../models/form_builder/form_field.dart' as form_models;

/// Preview Checkbox Group Field - Multiple checkboxes field
class PreviewCheckboxGroupField extends StatelessWidget {
  final form_models.FormField field;
  final dynamic value;
  final Function(dynamic) onChanged;
  final bool hasError;

  const PreviewCheckboxGroupField({
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
    
    final selectedValues = value is List ? (value as List).map((e) => e.toString()).toList() : <String>[];
    final minSelections = field.props['minSelections'] ?? 0;
    final maxSelections = field.props['maxSelections'];

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

        // Checkbox Options
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ...options.map((option) {
                final isSelected = selectedValues.contains(option);
                return CheckboxListTile(
                  title: Text(option),
                  value: isSelected,
                  onChanged: (checked) {
                    _handleCheckboxChange(option, checked ?? false, selectedValues);
                  },
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                );
              }),

              // Selection count indicator
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    _getSelectionText(selectedValues.length, minSelections, maxSelections),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleCheckboxChange(String option, bool checked, List<String> currentValues) {
    final newValues = List<String>.from(currentValues);
    
    if (checked) {
      if (!newValues.contains(option)) {
        newValues.add(option);
      }
    } else {
      newValues.remove(option);
    }

    debugPrint('CheckboxGroup ${field.id}: ${checked ? "Added" : "Removed"} "$option". New values: $newValues');
    onChanged(newValues);
  }

  String _getSelectionText(int count, int min, int? max) {
    final parts = <String>[];
    
    parts.add('$count selected');
    
    if (min > 0 || max != null) {
      final constraints = <String>[];
      if (min > 0) constraints.add('min: $min');
      if (max != null) constraints.add('max: $max');
      parts.add('(${constraints.join(', ')})');
    }

    return parts.join(' ');
  }
}
