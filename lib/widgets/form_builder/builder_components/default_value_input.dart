import 'package:flutter/material.dart';
import '../../../models/form_builder/form_field.dart' as form_models;
import '../../../providers/form_builder_provider.dart';

/// Default value input widget for all field types
class DefaultValueInput extends StatelessWidget {
  final FormBuilderProvider provider;
  final form_models.FormField field;

  const DefaultValueInput({
    super.key,
    required this.provider,
    required this.field,
  });

  @override
  Widget build(BuildContext context) {
    // Build appropriate input based on field type
    switch (field.type) {
      case form_models.FieldType.checkbox:
        return _buildCheckboxDefault();
      case form_models.FieldType.select:
      case form_models.FieldType.radio:
        return _buildSelectDefault();
      case form_models.FieldType.checkboxGroup:
        return _buildCheckboxGroupDefault();
      case form_models.FieldType.number:
        return _buildNumberDefault();
      case form_models.FieldType.date:
        return _buildDateDefault(context);
      case form_models.FieldType.time:
        return _buildTimeDefault(context);
      case form_models.FieldType.textarea:
        return _buildTextareaDefault();
      default:
        return _buildTextDefault();
    }
  }

  Widget _buildCheckboxDefault() {
    return SwitchListTile(
      title: const Text('Default checked state'),
      value: field.defaultValue == true,
      onChanged: (value) {
        provider.updateField(field.id, {'defaultValue': value});
      },
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSelectDefault() {
    final options = List<String>.from(field.props['options'] ?? []);
    
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Default selection',
        border: OutlineInputBorder(),
      ),
      initialValue: field.defaultValue?.toString(),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('No default selection'),
        ),
        ...options.map((option) => DropdownMenuItem<String>(
              value: option,
              child: Text(option),
            )),
      ],
      onChanged: (value) {
        provider.updateField(field.id, {'defaultValue': value});
      },
    );
  }

  Widget _buildCheckboxGroupDefault() {
    final options = List<String>.from(field.props['options'] ?? []);
    final selectedOptions = List<String>.from(field.defaultValue ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('Default selections:'),
        const SizedBox(height: 8),
        ...options.map((option) {
          final isSelected = selectedOptions.contains(option);
          return CheckboxListTile(
            title: Text(option),
            value: isSelected,
            onChanged: (bool? value) {
              List<String> newSelected = List.from(selectedOptions);
              if (value == true) {
                newSelected.add(option);
              } else {
                newSelected.remove(option);
              }
              provider.updateField(field.id, {'defaultValue': newSelected});
            },
            contentPadding: EdgeInsets.zero,
          );
        }),
      ],
    );
  }

  Widget _buildNumberDefault() {
    return TextField(
      decoration: InputDecoration(
        labelText: 'Default value',
        border: const OutlineInputBorder(),
        hintText: 'Enter default number',
        helperText: field.props['min'] != null || field.props['max'] != null
            ? 'Min: ${field.props['min'] ?? 'none'}, Max: ${field.props['max'] ?? 'none'}'
            : null,
      ),
      controller: TextEditingController(text: field.defaultValue?.toString() ?? ''),
      keyboardType: TextInputType.number,
      onChanged: (value) {
        final numValue = num.tryParse(value);
        provider.updateField(field.id, {'defaultValue': numValue});
      },
    );
  }

  Widget _buildDateDefault(BuildContext context) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
        );
        if (date != null) {
          provider.updateField(field.id, {
            'defaultValue': date.toIso8601String().split('T')[0]
          });
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Default date',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          field.defaultValue?.toString() ?? 'Select date',
          style: TextStyle(
            color: field.defaultValue != null ? Colors.black : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeDefault(BuildContext context) {
    return InkWell(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (time != null) {
          provider.updateField(field.id, {
            'defaultValue': '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
          });
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Default time',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.access_time),
        ),
        child: Text(
          field.defaultValue?.toString() ?? 'Select time',
          style: TextStyle(
            color: field.defaultValue != null ? Colors.black : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildTextareaDefault() {
    return TextField(
      decoration: InputDecoration(
        labelText: 'Default value',
        border: const OutlineInputBorder(),
        hintText: 'Enter default text',
        helperText: field.props['maxLength'] != null
            ? 'Max length: ${field.props['maxLength']}'
            : null,
      ),
      controller: TextEditingController(text: field.defaultValue?.toString() ?? ''),
      maxLines: 3,
      maxLength: field.props['maxLength'],
      onChanged: (value) {
        provider.updateField(field.id, {'defaultValue': value});
      },
    );
  }

  Widget _buildTextDefault() {
    return TextField(
      decoration: InputDecoration(
        labelText: 'Default value',
        border: const OutlineInputBorder(),
        hintText: 'Enter default value',
        helperText: field.props['maxLength'] != null
            ? 'Max length: ${field.props['maxLength']}'
            : null,
      ),
      controller: TextEditingController(text: field.defaultValue?.toString() ?? ''),
      maxLength: field.props['maxLength'],
      onChanged: (value) {
        provider.updateField(field.id, {'defaultValue': value});
      },
    );
  }
}
