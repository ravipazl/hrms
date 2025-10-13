import 'package:flutter/material.dart';
import '../../../../models/form_builder/form_field.dart' as form_models;

/// Preview Time Field - Functional time picker field
class PreviewTimeField extends StatelessWidget {
  final form_models.FormField field;
  final dynamic value;
  final Function(dynamic) onChanged;
  final bool hasError;

  const PreviewTimeField({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    TimeOfDay? selectedTime;
    
    if (value != null && value is String && value.isNotEmpty) {
      try {
        final parts = value.split(':');
        if (parts.length >= 2) {
          selectedTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
      } catch (e) {
        selectedTime = null;
      }
    }

    final timeText = selectedTime != null
        ? selectedTime.format(context)
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

        // Time Picker Button
        InkWell(
          onTap: () => _selectTime(context),
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
                  Icons.access_time,
                  size: 20,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    timeText.isEmpty ? 'Select time' : timeText,
                    style: TextStyle(
                      fontSize: 14,
                      color: timeText.isEmpty ? Colors.grey[600] : Colors.black87,
                    ),
                  ),
                ),
                if (timeText.isNotEmpty)
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

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      final timeString = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      onChanged(timeString);
    }
  }
}
