import 'package:flutter/material.dart';
import '../../../models/form_builder/form_field.dart' as form_models;
import '../field_renderers/dynamic_table_field_renderer.dart';
import 'field_renderers/preview_text_field.dart';
import 'field_renderers/preview_number_field.dart';
import 'field_renderers/preview_textarea_field.dart';
import 'field_renderers/preview_select_field.dart';
import 'field_renderers/preview_radio_field.dart';
import 'field_renderers/preview_checkbox_field.dart';
import 'field_renderers/preview_checkbox_group_field.dart';
import 'field_renderers/preview_date_field.dart';
import 'field_renderers/preview_time_field.dart';
import 'field_renderers/preview_file_field.dart';
import 'field_renderers/preview_signature_field.dart';
import 'field_renderers/preview_rich_text_field.dart';
 
/// Preview Field Renderer - Routes to appropriate field renderer based on type
/// Matches React's Field.jsx component
class PreviewFieldRenderer extends StatelessWidget {
  final form_models.FormField field;
  final dynamic value;
  final Function(dynamic) onChanged;
  final List<String>? error;

  const PreviewFieldRenderer({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    // Width is handled by parent grid layout using Expanded(flex: field.width)
    // No need to apply constraints here
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Field renderer based on type
        _buildFieldWidget(),

        // Error messages
        if (error != null && error!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  error!.map((errorMsg) {
                    return Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 16,
                          color: Colors.red[600],
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            errorMsg,
                            style: TextStyle(
                              color: Colors.red[600],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildFieldWidget() {
    switch (field.type) {
      case form_models.FieldType.text:
      case form_models.FieldType.email:
      case form_models.FieldType.password:
      case form_models.FieldType.url:
      case form_models.FieldType.tel:
        return PreviewTextField(
          field: field,
          value: value,
          onChanged: onChanged,
          hasError: error != null && error!.isNotEmpty,
        );

      case form_models.FieldType.number:
        return PreviewNumberField(
          field: field,
          value: value,
          onChanged: onChanged,
          hasError: error != null && error!.isNotEmpty,
        );

      case form_models.FieldType.textarea:
        return PreviewTextAreaField(
          field: field,
          value: value,
          onChanged: onChanged,
          hasError: error != null && error!.isNotEmpty,
        );

      case form_models.FieldType.select:
        return PreviewSelectField(
          field: field,
          value: value,
          onChanged: onChanged,
          hasError: error != null && error!.isNotEmpty,
        );

      case form_models.FieldType.radio:
        return PreviewRadioField(
          field: field,
          value: value,
          onChanged: onChanged,
          hasError: error != null && error!.isNotEmpty,
        );

      case form_models.FieldType.checkbox:
        return PreviewCheckboxField(
          field: field,
          value: value,
          onChanged: onChanged,
          hasError: error != null && error!.isNotEmpty,
        );

      case form_models.FieldType.checkboxGroup:
        return PreviewCheckboxGroupField(
          field: field,
          value: value,
          onChanged: onChanged,
          hasError: error != null && error!.isNotEmpty,
        );

      case form_models.FieldType.date:
        return PreviewDateField(
          field: field,
          value: value,
          onChanged: onChanged,
          hasError: error != null && error!.isNotEmpty,
        );

      case form_models.FieldType.time:
        return PreviewTimeField(
          field: field,
          value: value,
          onChanged: onChanged,
          hasError: error != null && error!.isNotEmpty,
        );

      case form_models.FieldType.file:
        return PreviewFileField(
          field: field,
          value: value,
          onChanged: onChanged,
          hasError: error != null && error!.isNotEmpty,
        );

      case form_models.FieldType.signature:
        return PreviewSignatureField(
          field: field,
          value: value,
          onChanged: onChanged,
          hasError: error != null && error!.isNotEmpty,
        );

      case form_models.FieldType.table:
        return DynamicTableFieldRenderer(
          field: field,
          isBuilder: false,
          value: value,
          onChanged: onChanged,
        );

      case form_models.FieldType.richText:
        print('\n🔍🔍🔍 RENDERING RICH TEXT FIELD: ${field.id}');
        print('   Field props keys: ${field.props.keys.toList()}');
        print('   Current value type: ${value.runtimeType}');
        print('   Current value: $value');
        
        return PreviewRichTextField(
          field: field,
          value: value,
          onChanged: (newValue) {
            print('\n📣📣📣 RICH TEXT onChanged CALLED!');
            print('   Field ID: ${field.id}');
            print('   New value type: ${newValue.runtimeType}');
            print('   New value keys: ${newValue is Map ? (newValue as Map).keys.toList() : "not a map"}');
            print('   embeddedFieldValues: ${newValue is Map ? newValue["embeddedFieldValues"] : "N/A"}');
            print('   Calling parent onChanged...');
            onChanged(newValue);
            print('   ✅ Parent onChanged completed\n');
          },
          hasError: error != null && error!.isNotEmpty,
        );

      default:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.orange[300]!),
            borderRadius: BorderRadius.circular(8),
            color: Colors.orange[50],
          ),
          child: Text(
            'Field type "${field.type.toShortString()}" renderer not implemented',
            style: TextStyle(color: Colors.orange[900]),
          ),
        );
    }
  }
}
