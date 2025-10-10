import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/form_builder/form_field.dart' as form_models;
import '../../../providers/form_builder_provider.dart';
import 'expandable_section.dart';
import 'default_value_input.dart';
import 'enhanced_table_settings_panel.dart';
import 'property_text_field.dart'; // NEW: Import the stateful text field

/// Enhanced field properties panel with full customization
class EnhancedFieldPropertiesPanel extends StatelessWidget {
  const EnhancedFieldPropertiesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FormBuilderProvider>(
      builder: (context, provider, _) {
        final field = provider.selectedField;

        if (field == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Select a field to edit its properties',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Header with actions
            _buildHeader(context, provider, field),

            // Scrollable content
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Basic Settings Section
                  ExpandableSection(
                    title: 'Basic Settings',
                    icon: Icons.settings,
                    initiallyExpanded: true,
                    child: _buildBasicSettings(provider, field),
                  ),

                  // Field-Specific Settings
                  _buildFieldSpecificSection(provider, field),

                  // Default Value Section
                  if (field.type != form_models.FieldType.richText &&
                      field.type != form_models.FieldType.table)
                    ExpandableSection(
                      title: 'Default Value',
                      icon: Icons.edit_note,
                      initiallyExpanded: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Set a default value that will be pre-filled when the form loads',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 12),
                          DefaultValueInput(provider: provider, field: field),
                        ],
                      ),
                    ),

                  // Validation & Limits Section
                  if (field.type != form_models.FieldType.table)
                    ExpandableSection(
                      title: 'Validation & Limits',
                      icon: Icons.verified_user,
                      initiallyExpanded: false,
                      child: _buildValidationSettings(provider, field),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    FormBuilderProvider provider,
    form_models.FormField field,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Field Settings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Field Type Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[600],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  field.type.toShortString().toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Duplicate'),
                  onPressed: () => provider.duplicateField(field.id),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete'),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Field'),
                        content: const Text('Are you sure you want to delete this field?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              provider.deleteField(field.id);
                              Navigator.pop(ctx);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBasicSettings(
    FormBuilderProvider provider,
    form_models.FormField field,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Label - FIXED with PropertyTextField
        PropertyTextField(
          initialValue: field.label,
          labelText: 'Field Label',
          onChanged: (value) => provider.updateField(field.id, {'label': value}),
        ),
        const SizedBox(height: 16),

        // Width and Height
        Row(
          children: [
            Expanded(
              child: PropertyTextField(
                initialValue: field.width.toString(),
                labelText: 'Width (1-12)',
                helperText: 'Grid columns',
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final width = int.tryParse(value);
                  if (width != null && width >= 1 && width <= 12) {
                    provider.updateField(field.id, {'width': width});
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PropertyTextField(
                initialValue: field.height.toString(),
                labelText: 'Height (rows)',
                helperText: 'Row span',
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final height = int.tryParse(value);
                  if (height != null && height >= 1 && height <= 12) {
                    provider.updateField(field.id, {'height': height});
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Required
        if (field.type != form_models.FieldType.checkbox &&
            field.type != form_models.FieldType.richText)
          SwitchListTile(
            title: const Text('Required field'),
            value: field.required,
            onChanged: (value) => provider.updateField(field.id, {'required': value}),
            contentPadding: EdgeInsets.zero,
          ),
      ],
    );
  }

  Widget _buildFieldSpecificSection(
    FormBuilderProvider provider,
    form_models.FormField field,
  ) {
    Widget? content;
    String title = 'Field Configuration';
    IconData icon = Icons.tune;
    Color? headerColor;

    // Determine field-specific content
    if (field.type == form_models.FieldType.text ||
        field.type == form_models.FieldType.email ||
        field.type == form_models.FieldType.password ||
        field.type == form_models.FieldType.url ||
        field.type == form_models.FieldType.tel) {
      title = 'Text Input Settings';
      content = _buildTextInputSettings(provider, field);
    } else if (field.type == form_models.FieldType.number) {
      title = 'Number Input Settings';
      content = _buildNumberInputSettings(provider, field);
    } else if (field.type == form_models.FieldType.textarea) {
      title = 'Textarea Settings';
      content = _buildTextareaSettings(provider, field);
    } else if (field.type == form_models.FieldType.select ||
        field.type == form_models.FieldType.radio) {
      title = 'Options Configuration';
      content = _buildOptionsSettings(provider, field);
    } else if (field.type == form_models.FieldType.checkboxGroup) {
      title = 'Checkbox Group Settings';
      content = _buildCheckboxGroupSettings(provider, field);
    } else if (field.type == form_models.FieldType.file) {
      title = 'File Upload Configuration';
      icon = Icons.upload_file;
      content = _buildFileUploadSettings(provider, field);
    } else if (field.type == form_models.FieldType.signature) {
      title = 'Signature Settings';
      icon = Icons.draw;
      content = _buildSignatureSettings(provider, field);
    } else if (field.type == form_models.FieldType.table) {
      // Use the full-featured EnhancedTableSettingsPanel
      return EnhancedTableSettingsPanel(provider: provider, field: field);
    } else if (field.type == form_models.FieldType.richText) {
      title = 'Rich Text Configuration';
      icon = Icons.text_fields;
      headerColor = Colors.orange[50];
      content = _buildRichTextSettings(provider, field);
    }

    if (content == null) {
      return const SizedBox.shrink();
    }

    return ExpandableSection(
      title: title,
      icon: icon,
      initiallyExpanded: true,
      headerColor: headerColor,
      child: content,
    );
  }

  Widget _buildValidationSettings(
    FormBuilderProvider provider,
    form_models.FormField field,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Configure validation rules for this field',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        
        // Add validation rules based on field type
        if (field.type == form_models.FieldType.text ||
            field.type == form_models.FieldType.password ||
            field.type == form_models.FieldType.textarea)
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: PropertyTextField(
                      initialValue: field.props['minLength']?.toString() ?? '',
                      labelText: 'Min Length',
                      helperText: 'Minimum characters',
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final intValue = value.isEmpty ? null : int.tryParse(value);
                        provider.updateField(field.id, {'minLength': intValue});
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PropertyTextField(
                      initialValue: field.props['maxLength']?.toString() ?? '',
                      labelText: 'Max Length',
                      helperText: 'Maximum characters',
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final intValue = value.isEmpty ? null : int.tryParse(value);
                        provider.updateField(field.id, {'maxLength': intValue});
                      },
                    ),
                  ),
                ],
              ),
            ],
          )
        else if (field.type == form_models.FieldType.number)
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: PropertyTextField(
                      initialValue: field.props['min']?.toString() ?? '',
                      labelText: 'Min Value',
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final numValue = value.isEmpty ? null : num.tryParse(value);
                        provider.updateField(field.id, {'min': numValue});
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PropertyTextField(
                      initialValue: field.props['max']?.toString() ?? '',
                      labelText: 'Max Value',
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final numValue = value.isEmpty ? null : num.tryParse(value);
                        provider.updateField(field.id, {'max': numValue});
                      },
                    ),
                  ),
                ],
              ),
            ],
          )
        else
          Text(
            'No validation options for this field type',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  // TEXT INPUT SETTINGS
  Widget _buildTextInputSettings(
    FormBuilderProvider provider,
    form_models.FormField field,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Placeholder
        PropertyTextField(
          initialValue: field.placeholder ?? '',
          labelText: 'Placeholder',
          hintText: 'Enter placeholder text...',
          onChanged: (value) => provider.updateField(field.id, {'placeholder': value}),
        ),

        // Password-specific settings
        if (field.type == form_models.FieldType.password) ...[
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Password Options',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Show strength indicator'),
            subtitle: const Text('Display password strength meter'),
            value: field.props['showStrengthIndicator'] ?? true,
            onChanged: (value) {
              provider.updateField(field.id, {'showStrengthIndicator': value});
            },
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('Confirm password field'),
            subtitle: const Text('Require password confirmation'),
            value: field.props['confirmPassword'] ?? false,
            onChanged: (value) {
              provider.updateField(field.id, {'confirmPassword': value});
            },
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ],
    );
  }

  // NUMBER INPUT SETTINGS
  Widget _buildNumberInputSettings(
    FormBuilderProvider provider,
    form_models.FormField field,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Placeholder
        PropertyTextField(
          initialValue: field.placeholder ?? '',
          labelText: 'Placeholder',
          onChanged: (value) => provider.updateField(field.id, {'placeholder': value}),
        ),
        const SizedBox(height: 16),

        // Step
        PropertyTextField(
          initialValue: field.props['step']?.toString() ?? '1',
          labelText: 'Step',
          helperText: 'Increment/decrement value',
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final numValue = num.tryParse(value) ?? 1;
            provider.updateField(field.id, {'step': numValue});
          },
        ),
      ],
    );
  }

  // TEXTAREA SETTINGS
  Widget _buildTextareaSettings(
    FormBuilderProvider provider,
    form_models.FormField field,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Placeholder
        PropertyTextField(
          initialValue: field.placeholder ?? '',
          labelText: 'Placeholder',
          onChanged: (value) => provider.updateField(field.id, {'placeholder': value}),
        ),
        const SizedBox(height: 16),

        // Rows
        PropertyTextField(
          initialValue: field.props['rows']?.toString() ?? '4',
          labelText: 'Rows',
          helperText: 'Number of visible rows (2-20)',
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final intValue = int.tryParse(value);
            if (intValue != null && intValue >= 2 && intValue <= 20) {
              provider.updateField(field.id, {'rows': intValue});
            }
          },
        ),
      ],
    );
  }

  // OPTIONS SETTINGS (Select/Radio)
  Widget _buildOptionsSettings(
    FormBuilderProvider provider,
    form_models.FormField field,
  ) {
    final options = List<String>.from(field.props['options'] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Options',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                options.add('Option ${options.length + 1}');
                provider.updateField(field.id, {'options': options});
              },
              tooltip: 'Add Option',
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Options List
        if (options.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Center(
              child: Text(
                'No options added yet',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ...options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: PropertyTextField(
                    key: ValueKey('option_${field.id}_$index'),
                    initialValue: option,
                    labelText: 'Option ${index + 1}',
                    onChanged: (value) {
                      options[index] = value;
                      provider.updateField(field.id, {'options': options});
                    },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      options.removeAt(index);
                      provider.updateField(field.id, {'options': options});
                    },
                    tooltip: 'Remove option',
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // CHECKBOX GROUP SETTINGS
  Widget _buildCheckboxGroupSettings(
    FormBuilderProvider provider,
    form_models.FormField field,
  ) {
    final options = List<String>.from(field.props['options'] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Options Management
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Checkbox Options', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blue)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                options.add('Option ${options.length + 1}');
                provider.updateField(field.id, {'options': options});
              },
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (options.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Center(child: Text('No options added yet', style: TextStyle(color: Colors.grey))),
          )
        else
          ...options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: PropertyTextField(
                    key: ValueKey('cbg_option_${field.id}_$index'),
                    initialValue: option,
                    labelText: 'Option ${index + 1}',
                    onChanged: (value) {
                      options[index] = value;
                      provider.updateField(field.id, {'options': options});
                    },
                    ),
                    ),
                    IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      options.removeAt(index);
                      provider.updateField(field.id, {'options': options});
                    },
                  ),
                ],
              ),
            );
          }),

        const Divider(height: 32),

        // Selection Limits
        const Text('Selection Limits', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: PropertyTextField(
                initialValue: field.props['minSelections']?.toString() ?? '0',
                labelText: 'Min Selections',
                helperText: 'Minimum (0 = optional)',
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final intValue = int.tryParse(value);
                  if (intValue != null && intValue >= 0) {
                    provider.updateField(field.id, {'minSelections': intValue});
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PropertyTextField(
                initialValue: field.props['maxSelections']?.toString() ?? '',
                labelText: 'Max Selections',
                helperText: 'Maximum (empty = unlimited)',
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final intValue = value.isEmpty ? null : int.tryParse(value);
                  provider.updateField(field.id, {'maxSelections': intValue});
                },
              ),
            ),
          ],
        ),

        const Divider(height: 32),

        // Layout Options
        const Text('Layout Options', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Layout',
            border: OutlineInputBorder(),
            helperText: 'How options are arranged',
          ),
          initialValue: field.props['layout']?.toString() ?? 'vertical',
          items: const [
            DropdownMenuItem(value: 'vertical', child: Text('Vertical (stacked)')),
            DropdownMenuItem(value: 'horizontal', child: Text('Horizontal (inline)')),
            DropdownMenuItem(value: 'grid', child: Text('Grid (2 columns)')),
          ],
          onChanged: (value) {
            provider.updateField(field.id, {'layout': value});
          },
        ),

        const Divider(height: 32),

        // Other Option
        const Text('"Other" Option', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Allow "Other" option'),
          subtitle: const Text('Let users specify a custom value'),
          value: field.props['allowOther'] ?? false,
          onChanged: (value) => provider.updateField(field.id, {'allowOther': value}),
          contentPadding: EdgeInsets.zero,
        ),
        if (field.props['allowOther'] == true) ...[
          const SizedBox(height: 12),
          PropertyTextField(
            initialValue: field.props['otherLabel'] ?? 'Other',
            labelText: '"Other" Label',
            hintText: 'Other (please specify)',
            onChanged: (value) {
              provider.updateField(field.id, {'otherLabel': value});
            },
          ),
        ],
      ],
    );
  }

  // FILE UPLOAD SETTINGS
  Widget _buildFileUploadSettings(
    FormBuilderProvider provider,
    form_models.FormField field,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Help Text
        PropertyTextField(
          initialValue: field.props['helpText'] ?? '',
          labelText: 'Help Text',
          hintText: 'e.g., Upload your documents here',
          helperText: 'Additional instructions for users',
          maxLines: 2,
          onChanged: (value) => provider.updateField(field.id, {'helpText': value}),
        ),
        const SizedBox(height: 16),

        // File Type Preset
        const Text('File Type Restrictions', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'File Type Preset',
            border: OutlineInputBorder(),
            helperText: 'Quick preset for common file types',
          ),
          initialValue: _getFileTypePreset(field.props['accept']),
          items: const [
            DropdownMenuItem(value: '*', child: Text('All Types')),
            DropdownMenuItem(value: 'image/*', child: Text('Images Only')),
            DropdownMenuItem(value: '.pdf', child: Text('PDF Only')),
            DropdownMenuItem(value: 'image/*,.pdf', child: Text('Images & PDFs')),
            DropdownMenuItem(value: 'documents', child: Text('Documents (PDF, Word)')),
            DropdownMenuItem(value: 'spreadsheets', child: Text('Spreadsheets (Excel, CSV)')),
          ],
          onChanged: (value) {
            String acceptValue;
            List<String> allowedTypes;

            switch (value) {
              case '*':
                acceptValue = '*';
                allowedTypes = ['*'];
                break;
              case 'image/*':
                acceptValue = 'image/*';
                allowedTypes = ['image/*'];
                break;
              case '.pdf':
                acceptValue = '.pdf,application/pdf';
                allowedTypes = ['.pdf', 'pdf', 'application/pdf'];
                break;
              case 'image/*,.pdf':
                acceptValue = 'image/*,.pdf,application/pdf';
                allowedTypes = ['image/*', '.pdf', 'pdf', 'application/pdf'];
                break;
              case 'documents':
                acceptValue = '.pdf,.doc,.docx,application/pdf';
                allowedTypes = ['.pdf', 'pdf', '.doc', '.docx'];
                break;
              case 'spreadsheets':
                acceptValue = '.xls,.xlsx,.csv';
                allowedTypes = ['.xls', '.xlsx', '.csv'];
                break;
              default:
                acceptValue = '*';
                allowedTypes = ['*'];
            }

            provider.updateField(field.id, {
              'accept': acceptValue,
              'allowedTypes': allowedTypes,
            });
          },
        ),

        const Divider(height: 32),

        // File Quantity
        const Text('File Quantity', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Allow multiple files'),
          subtitle: const Text('Users can upload more than one file'),
          value: field.props['multiple'] ?? false,
          onChanged: (value) => provider.updateField(field.id, {'multiple': value}),
          contentPadding: EdgeInsets.zero,
        ),
        if (field.props['multiple'] == true) ...[
          const SizedBox(height: 12),
          PropertyTextField(
            initialValue: field.props['maxFiles']?.toString() ?? '5',
            labelText: 'Max Number of Files',
            helperText: 'Maximum files allowed (1-20)',
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final intValue = int.tryParse(value);
              if (intValue != null && intValue >= 1 && intValue <= 20) {
                provider.updateField(field.id, {'maxFiles': intValue});
              }
            },
          ),
        ],

        const Divider(height: 32),

        // File Size Limits
        const Text('File Size Limits', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        PropertyTextField(
          initialValue: ((field.props['maxFileSize'] ?? 10485760) / 1048576).toString(),
          labelText: 'Max File Size (MB)',
          helperText: 'Maximum size per file (1-100)',
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final doubleValue = double.tryParse(value);
            if (doubleValue != null && doubleValue >= 1 && doubleValue <= 100) {
              provider.updateField(field.id, {
                'maxFileSize': (doubleValue * 1048576).toInt(),
              });
            }
          },
        ),

        const Divider(height: 32),

        // UI Preferences
        const Text('UI Preferences', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Show file previews'),
          subtitle: const Text('Display thumbnails for images'),
          value: field.props['showPreview'] ?? true,
          onChanged: (value) => provider.updateField(field.id, {'showPreview': value}),
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: const Text('Show file sizes'),
          subtitle: const Text('Display file size for each upload'),
          value: field.props['showFileSize'] ?? true,
          onChanged: (value) => provider.updateField(field.id, {'showFileSize': value}),
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: const Text('Allow file removal'),
          subtitle: const Text('Users can remove uploaded files'),
          value: field.props['allowRemove'] ?? true,
          onChanged: (value) => provider.updateField(field.id, {'allowRemove': value}),
          contentPadding: EdgeInsets.zero,
        ),

        const Divider(height: 32),

        // Image Compression
        const Text('Advanced Features', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Enable image compression'),
          subtitle: const Text('Automatically compress images before upload'),
          value: field.props['compressionEnabled'] ?? false,
          onChanged: (value) => provider.updateField(field.id, {'compressionEnabled': value}),
          contentPadding: EdgeInsets.zero,
        ),
        if (field.props['compressionEnabled'] == true) ...[
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Compression Quality: ${(field.props['compressionQuality'] ?? 0.8).toStringAsFixed(1)}',
                style: const TextStyle(fontSize: 12),
              ),
              Slider(
                value: (field.props['compressionQuality'] ?? 0.8).toDouble(),
                min: 0.1,
                max: 1.0,
                divisions: 9,
                label: (field.props['compressionQuality'] ?? 0.8).toStringAsFixed(1),
                onChanged: (value) {
                  provider.updateField(field.id, {'compressionQuality': value});
                },
              ),
              Text(
                'Higher = better quality, larger file size',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _getFileTypePreset(String? accept) {
    if (accept == null || accept == '*') return '*';
    if (accept == 'image/*') return 'image/*';
    if (accept.contains('.pdf') && !accept.contains('image')) return '.pdf';
    if (accept.contains('image/*') && accept.contains('.pdf')) return 'image/*,.pdf';
    if (accept.contains('.doc')) return 'documents';
    if (accept.contains('.xls') || accept.contains('.csv')) return 'spreadsheets';
    return '*';
  }

  // SIGNATURE SETTINGS
  Widget _buildSignatureSettings(
    FormBuilderProvider provider,
    form_models.FormField field,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Color Settings', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),

        // Pen Color & Background Color
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pen Color', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: _hexToColor(field.props['penColor'] ?? '#000000'),
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Background Color', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: _hexToColor(field.props['backgroundColor'] ?? '#ffffff'),
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const Divider(height: 32),

        // Button Options
        const Text('Button Options', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Show clear button'),
          subtitle: const Text('Allow users to clear signature'),
          value: field.props['clearButton'] ?? true,
          onChanged: (value) => provider.updateField(field.id, {'clearButton': value}),
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: const Text('Show download button'),
          subtitle: const Text('Allow users to download signature'),
          value: field.props['downloadButton'] ?? false,
          onChanged: (value) => provider.updateField(field.id, {'downloadButton': value}),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  // TABLE SETTINGS
  Widget _buildTableSettings(
    FormBuilderProvider provider,
    form_models.FormField field,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row Configuration
        const Text('Row Configuration', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blue)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: PropertyTextField(
                initialValue: field.props['minRows']?.toString() ?? '1',
                labelText: 'Min Rows',
                helperText: 'Minimum required',
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final intValue = int.tryParse(value);
                  if (intValue != null && intValue >= 1) {
                    provider.updateField(field.id, {'minRows': intValue});
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PropertyTextField(
                initialValue: field.props['maxRows']?.toString() ?? '50',
                labelText: 'Max Rows',
                helperText: 'Maximum allowed',
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final intValue = int.tryParse(value);
                  if (intValue != null && intValue >= 1) {
                    provider.updateField(field.id, {'maxRows': intValue});
                  }
                },
              ),
            ),
          ],
        ),

        const Divider(height: 32),

        // Row Permissions
        const Text('Row Permissions', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Allow adding rows'),
          value: field.props['allowAddRows'] ?? true,
          onChanged: (value) => provider.updateField(field.id, {'allowAddRows': value}),
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: const Text('Allow deleting rows'),
          value: field.props['allowDeleteRows'] ?? true,
          onChanged: (value) => provider.updateField(field.id, {'allowDeleteRows': value}),
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: const Text('Allow reordering rows'),
          value: field.props['allowReorderRows'] ?? true,
          onChanged: (value) => provider.updateField(field.id, {'allowReorderRows': value}),
          contentPadding: EdgeInsets.zero,
        ),

        const Divider(height: 32),

        // Column Permissions (NEW SECTION)
        const Text('Column Permissions', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Allow adding columns'),
          subtitle: const Text('Users can add new columns'),
          value: field.props['allowAddColumns'] ?? true,
          onChanged: (value) => provider.updateField(field.id, {'allowAddColumns': value}),
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: const Text('Allow deleting columns'),
          subtitle: const Text('Users can remove columns'),
          value: field.props['allowDeleteColumns'] ?? true,
          onChanged: (value) => provider.updateField(field.id, {'allowDeleteColumns': value}),
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: const Text('Allow reordering columns'),
          subtitle: const Text('Users can rearrange column order'),
          value: field.props['allowReorderColumns'] ?? true,
          onChanged: (value) => provider.updateField(field.id, {'allowReorderColumns': value}),
          contentPadding: EdgeInsets.zero,
        ),

        const Divider(height: 32),

        // Display Options
        const Text('Display Options', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Show row numbers'),
          value: field.props['showRowNumbers'] ?? true,
          onChanged: (value) => provider.updateField(field.id, {'showRowNumbers': value}),
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: const Text('Show auto serial numbers column'),
          subtitle: const Text('Automatically adds a fixed serial number column at the start'),
          value: field.props['showSerialNumbers'] ?? false,
          onChanged: (value) => provider.updateField(field.id, {'showSerialNumbers': value}),
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: const Text('Zebra striping'),
          subtitle: const Text('Alternating row colors'),
          value: field.props['striped'] ?? true,
          onChanged: (value) => provider.updateField(field.id, {'striped': value}),
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: const Text('Show borders'),
          value: field.props['bordered'] ?? true,
          onChanged: (value) => provider.updateField(field.id, {'bordered': value}),
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: const Text('Compact spacing'),
          value: field.props['compact'] ?? false,
          onChanged: (value) => provider.updateField(field.id, {'compact': value}),
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: const Text('Allow export to CSV'),
          value: field.props['exportable'] ?? true,
          onChanged: (value) => provider.updateField(field.id, {'exportable': value}),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  // RICH TEXT SETTINGS
  Widget _buildRichTextSettings(
    FormBuilderProvider provider,
    form_models.FormField field,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Placeholder
        PropertyTextField(
          initialValue: field.placeholder ?? '',
          labelText: 'Placeholder Text',
          hintText: 'Start typing your content...',
          onChanged: (value) => provider.updateField(field.id, {'placeholder': value}),
        ),
        const SizedBox(height: 16),

        // Required Field
        SwitchListTile(
          title: const Text('Required field'),
          subtitle: const Text('User must provide content'),
          value: field.required,
          onChanged: (value) => provider.updateField(field.id, {'required': value}),
          contentPadding: EdgeInsets.zero,
        ),

        const Divider(height: 32),

        // Toolbar Configuration
        const Text('Toolbar Configuration', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Toolbar Preset',
            border: OutlineInputBorder(),
            helperText: 'Controls available formatting options',
          ),
          initialValue: field.props['toolbar']?.toString() ?? 'standard',
          items: const [
            DropdownMenuItem(value: 'minimal', child: Text('Minimal - Basic formatting only')),
            DropdownMenuItem(value: 'standard', child: Text('Standard - Common formatting + links')),
            DropdownMenuItem(value: 'full', child: Text('Full - All features + interactive fields')),
          ],
          onChanged: (value) {
            provider.updateField(field.id, {'toolbar': value});
          },
        ),

        const Divider(height: 32),

        // Display Options
        const Text('Display Options', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Show word and character count'),
          subtitle: const Text('Display content statistics'),
          value: field.props['showWordCount'] ?? true,
          onChanged: (value) => provider.updateField(field.id, {'showWordCount': value}),
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 16),

        // Min/Max Height
        Row(
          children: [
            Expanded(
              child: PropertyTextField(
                initialValue: field.props['minHeight']?.toString() ?? '200',
                labelText: 'Min Height (px)',
                helperText: '100-1000',
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final intValue = int.tryParse(value);
                  if (intValue != null && intValue >= 100 && intValue <= 1000) {
                    provider.updateField(field.id, {'minHeight': intValue});
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PropertyTextField(
                initialValue: field.props['maxHeight']?.toString() ?? '600',
                labelText: 'Max Height (px)',
                helperText: '200-2000',
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final intValue = int.tryParse(value);
                  if (intValue != null && intValue >= 200 && intValue <= 2000) {
                    provider.updateField(field.id, {'maxHeight': intValue});
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
