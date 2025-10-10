import 'package:flutter/material.dart';
import '../../../models/form_builder/form_field.dart' as form_models;
import 'interactive_field_wrapper.dart';
import 'interactive_table_wrapper.dart';
import '../field_renderers/dynamic_table_field_renderer.dart';

class CanvasFieldRenderer {
  static Widget renderField(form_models.FormField field) {
    return renderFieldWithIndex(field, 0);
  }

  static Widget renderFieldWithIndex(form_models.FormField field, int index) {
    Widget fieldWidget;

    switch (field.type) {
      case form_models.FieldType.text:
      case form_models.FieldType.email:
      case form_models.FieldType.password:
      case form_models.FieldType.url:
      case form_models.FieldType.tel:
        fieldWidget = _buildTextField(field);
        break;
      case form_models.FieldType.number:
        fieldWidget = _buildNumberField(field);
        break;
      case form_models.FieldType.textarea:
        fieldWidget = _buildTextAreaField(field);
        break;
      case form_models.FieldType.select:
        fieldWidget = _buildSelectField(field);
        break;
      case form_models.FieldType.radio:
        fieldWidget = _buildRadioField(field);
        break;
      case form_models.FieldType.checkbox:
        fieldWidget = _buildCheckboxField(field);
        break;
      case form_models.FieldType.checkboxGroup:
        fieldWidget = _buildCheckboxGroupField(field);
        break;
      case form_models.FieldType.date:
        fieldWidget = _buildDateField(field);
        break;
      case form_models.FieldType.time:
        fieldWidget = _buildTimeField(field);
        break;
      case form_models.FieldType.file:
        fieldWidget = _buildFileField(field);
        break;
      case form_models.FieldType.table:
        // Use the dynamic table field renderer for full functionality
        fieldWidget = DynamicTableFieldRenderer(field: field, isBuilder: true);
        // Use specialized wrapper that doesn't block table interactions
        return InteractiveTableWrapper(
          field: field,
          index: index,
          child: fieldWidget,
        );
      case form_models.FieldType.richText:
        fieldWidget = _buildRichTextField(field);
        break;
      default:
        fieldWidget = _buildTextField(field);
    }

    return InteractiveFieldWrapper(
      field: field,
      index: index,
      child: fieldWidget,
    );
  }

  static Widget _buildTextField(form_models.FormField field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (field.label.isNotEmpty) ...[
          Row(
            children: [
              Text(field.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              if (field.required) const Text(' *', style: TextStyle(color: Colors.red)),
            ],
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          decoration: InputDecoration(
            hintText: field.props['placeholder'] ?? 'Enter ${field.type.toShortString()}...',
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  static Widget _buildNumberField(form_models.FormField field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (field.label.isNotEmpty) ...[
          Row(
            children: [
              Text(field.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              if (field.required) const Text(' *', style: TextStyle(color: Colors.red)),
            ],
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          decoration: InputDecoration(
            hintText: field.props['placeholder'] ?? 'Enter number...',
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  static Widget _buildTextAreaField(form_models.FormField field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (field.label.isNotEmpty) ...[
          Row(
            children: [
              Text(field.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              if (field.required) const Text(' *', style: TextStyle(color: Colors.red)),
            ],
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          decoration: InputDecoration(
            hintText: field.props['placeholder'] ?? 'Enter text...',
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.all(12),
          ),
          maxLines: field.props['rows'] ?? 4,
        ),
      ],
    );
  }

  static Widget _buildSelectField(form_models.FormField field) {
    final options = List<String>.from(field.props['options'] ?? ['Option 1', 'Option 2', 'Option 3']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (field.label.isNotEmpty) ...[
          Row(
            children: [
              Text(field.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              if (field.required) const Text(' *', style: TextStyle(color: Colors.red)),
            ],
          ),
          const SizedBox(height: 8),
        ],
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          hint: const Text('Select an option'),
          items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
          onChanged: (_) {},
        ),
      ],
    );
  }

  static Widget _buildRadioField(form_models.FormField field) {
    final options = List<String>.from(field.props['options'] ?? ['Option 1', 'Option 2']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (field.label.isNotEmpty) ...[
          Row(
            children: <Widget>[
              Text(field.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              if (field.required) const Text(' *', style: TextStyle(color: Colors.red)),
            ],
          ),
          const SizedBox(height: 8),
        ],
        ...options.map((opt) => RadioListTile<String>(
          title: Text(opt),
          value: opt,
          groupValue: null,
          onChanged: (_) {},
          contentPadding: EdgeInsets.zero,
          dense: true,
        )),
      ],
    );
  }

  static Widget _buildCheckboxField(form_models.FormField field) {
    return CheckboxListTile(
      title: Text(field.label.isNotEmpty ? field.label : 'Checkbox'),
      value: false,
      onChanged: (_) {},
      contentPadding: EdgeInsets.zero,
    );
  }

  static Widget _buildCheckboxGroupField(form_models.FormField field) {
    final options = List<String>.from(field.props['options'] ?? ['Option 1', 'Option 2', 'Option 3']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (field.label.isNotEmpty) ...[
          Row(
            children: [
              Text(field.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              if (field.required) const Text(' *', style: TextStyle(color: Colors.red)),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: options.map((opt) => CheckboxListTile(
              title: Text(opt),
              value: false,
              onChanged: (_) {},
              contentPadding: EdgeInsets.zero,
              dense: true,
            )).toList(),
          ),
        ),
      ],
    );
  }

  static Widget _buildDateField(form_models.FormField field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (field.label.isNotEmpty) ...[
          Row(
            children: [
              Text(field.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              if (field.required) const Text(' *', style: TextStyle(color: Colors.red)),
            ],
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          decoration: const InputDecoration(
            hintText: 'Select date',
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.calendar_today),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          readOnly: true,
        ),
      ],
    );
  }

  static Widget _buildTimeField(form_models.FormField field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (field.label.isNotEmpty) ...[
          Row(
            children: [
              Text(field.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              if (field.required) const Text(' *', style: TextStyle(color: Colors.red)),
            ],
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          decoration: const InputDecoration(
            hintText: 'Select time',
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.access_time),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          readOnly: true,
        ),
      ],
    );
  }

  static Widget _buildFileField(form_models.FormField field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (field.label.isNotEmpty) ...[
          Row(
            children: [
              Text(field.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              if (field.required) const Text(' *', style: TextStyle(color: Colors.red)),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(Icons.cloud_upload, size: 48, color: Colors.blue[300]),
              const SizedBox(height: 12),
              const Text('Click to upload or drag and drop', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Choose File'),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildRichTextField(form_models.FormField field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (field.label.isNotEmpty) ...[
          Row(
            children: [
              Text(field.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              if (field.required) const Text(' *', style: TextStyle(color: Colors.red)),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Wrap(
                  spacing: 4,
                  children: [
                    IconButton(icon: const Icon(Icons.format_bold, size: 18), onPressed: () {}, padding: const EdgeInsets.all(4), constraints: const BoxConstraints()),
                    IconButton(icon: const Icon(Icons.format_italic, size: 18), onPressed: () {}, padding: const EdgeInsets.all(4), constraints: const BoxConstraints()),
                    IconButton(icon: const Icon(Icons.format_underline, size: 18), onPressed: () {}, padding: const EdgeInsets.all(4), constraints: const BoxConstraints()),
                  ],
                ),
              ),
              TextField(
                decoration: InputDecoration(
                  hintText: field.props['placeholder'] ?? 'Start typing...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(12),
                ),
                maxLines: 5,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
