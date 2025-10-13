import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/form_builder_provider.dart';
import '../../../models/form_builder/form_field.dart' as form_models;

class FieldSidebar extends StatelessWidget {
  const FieldSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: const Row(
              children: [
                Icon(Icons.widgets, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Field Types',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                _buildFieldType(context, 'Text', Icons.text_fields, form_models.FieldType.text),
                _buildFieldType(context, 'Textarea', Icons.notes, form_models.FieldType.textarea),
                _buildFieldType(context, 'Number', Icons.numbers, form_models.FieldType.number),
                _buildFieldType(context, 'Email', Icons.email, form_models.FieldType.email),
                _buildFieldType(context, 'Date', Icons.calendar_today, form_models.FieldType.date),
                _buildFieldType(context, 'Select', Icons.arrow_drop_down_circle, form_models.FieldType.select),
                _buildFieldType(context, 'Checkbox', Icons.check_box, form_models.FieldType.checkbox),
                _buildFieldType(context, 'Multi-Checkbox', Icons.checklist, form_models.FieldType.checkboxGroup),
                _buildFieldType(context, 'Radio', Icons.radio_button_checked, form_models.FieldType.radio),
                _buildFieldType(context, 'File', Icons.attach_file, form_models.FieldType.file),
                _buildFieldType(context, 'Rich Text', Icons.text_format, form_models.FieldType.richText),
                _buildFieldType(context, 'Table', Icons.table_chart, form_models.FieldType.table),
                _buildFieldType(context, 'Signature', Icons.draw, form_models.FieldType.signature),
              ],
            ),
          ),
          
          // Helpful hint at bottom
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Click to add field to canvas',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldType(
    BuildContext context,
    String label,
    IconData icon,
    form_models.FieldType type,
  ) {
    return Draggable<form_models.FieldType>(
      data: type,
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 250,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue, width: 2),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.blue, size: 20),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: Card(
          child: ListTile(
            leading: Icon(icon, color: Colors.grey),
            title: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
        ),
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey[300]!),
        ),
        child: InkWell(
          onTap: () {
            final provider = Provider.of<FormBuilderProvider>(context, listen: false);
            provider.addField(type);
            
            // Show snackbar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$label field added'),
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: Colors.blue, size: 20),
            ),
            title: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              'Click or drag',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            trailing: Icon(Icons.add_circle_outline, color: Colors.grey[400]),
          ),
        ),
      ),
    );
  }
}
