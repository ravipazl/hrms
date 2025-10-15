import 'package:flutter/material.dart';
import '../../../models/form_builder/form_field.dart' as form_models;
import '../../../models/form_builder/enhanced_header_config.dart';
import '../header/form_header_preview.dart';
import 'preview_field_renderer.dart';

class FormPreviewScreen extends StatefulWidget {
  final List<form_models.FormField> fields;
  final String? formTitle;
  final String? formDescription;
  final HeaderConfig? headerConfig;
  final Function(Map<String, dynamic>)? onSubmit;
   
  const FormPreviewScreen({
    super.key,
    required this.fields,
    this.formTitle,
    this.formDescription,
    this.headerConfig,
    this.onSubmit,
  });

  @override
  State<FormPreviewScreen> createState() => _FormPreviewScreenState();
}

class _FormPreviewScreenState extends State<FormPreviewScreen> {
  final Map<String, dynamic> _formData = {};

  @override
  void initState() {
    super.initState();
    // Initialize form data with default values for fields
    for (final field in widget.fields) {
      if (field.defaultValue != null) {
        _formData[field.id] = field.defaultValue;
      } else if (field.type == form_models.FieldType.checkbox) {
        // Initialize checkbox to false if no default
        _formData[field.id] = false;
      } else if (field.type == form_models.FieldType.checkboxGroup) {
        // Initialize checkbox group to empty array if no default
        _formData[field.id] = [];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with full configuration (scrolls with content)
          FormHeaderPreview(
            formTitle: widget.formTitle,
            formDescription: widget.formDescription,
            headerConfig: widget.headerConfig ?? HeaderConfig.defaultConfig(),
            mode: 'preview',
          ),
          
          // Fields (combined with header in same scroll)
          if (widget.fields.isEmpty)
            const Padding(
              padding: EdgeInsets.all(48.0),
              child: Center(
                child: Text(
                  'No fields added yet',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildGridLayout(widget.fields),
            ),
          
          // Submit button (scrolls with content)
          if (widget.onSubmit != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => widget.onSubmit!(_formData),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Submit',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build fields with automatic grid layout
  /// Fields flow inline based on their width (12-column grid)
  Widget _buildGridLayout(List<form_models.FormField> fields) {
    final List<Widget> rows = [];
    List<Widget> currentRow = [];
    int currentRowWidth = 0;

    for (final field in fields) {
      final fieldWidth = field.width;

      // If adding this field exceeds 12 columns, start a new row
      if (currentRowWidth + fieldWidth > 12 && currentRow.isNotEmpty) {
        rows.add(_buildRow(currentRow, currentRowWidth));
        currentRow = [];
        currentRowWidth = 0;
      }

      // Add field to current row
      currentRow.add(
        Expanded(
          flex: fieldWidth,
          child: PreviewFieldRenderer(
            key: ValueKey('renderer_${field.id}'),
            field: field,
            value: _formData[field.id],
            onChanged: (value) {
              setState(() {
                _formData[field.id] = value;
                debugPrint('Field ${field.id} (${field.type.toShortString()}) changed to: $value');
              });
            },
          ),
        ),
      );
      currentRowWidth += fieldWidth;

      // If row is complete (12 columns), finalize it
      if (currentRowWidth >= 12) {
        rows.add(_buildRow(currentRow, currentRowWidth));
        currentRow = [];
        currentRowWidth = 0;
      }
    }

    // Add remaining fields in the last row
    if (currentRow.isNotEmpty) {
      rows.add(_buildRow(currentRow, currentRowWidth));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }

  Widget _buildRow(List<Widget> fields, int totalWidth) {
    // If row doesn't fill 12 columns, add spacer
    final List<Widget> rowChildren = List.from(fields);
    
    if (totalWidth < 12) {
      rowChildren.add(Expanded(flex: 12 - totalWidth, child: const SizedBox()));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rowChildren,
      ),
    );
  }
}
