import 'package:flutter/material.dart';
import '../../../providers/form_builder_provider.dart';
import '../../../models/form_builder/form_field.dart' as form_models;
import 'expandable_section.dart';
 
/// Enhanced Table Field Settings Panel - Configuration-Based Approach
/// Users configure table structure here, canvas shows preview only
class EnhancedTableSettingsPanel extends StatefulWidget {
  final FormBuilderProvider provider;
  final form_models.FormField field;

  const EnhancedTableSettingsPanel({
    super.key,
    required this.provider,
    required this.field,
  });

  @override
  State<EnhancedTableSettingsPanel> createState() => _EnhancedTableSettingsPanelState();
}

class _EnhancedTableSettingsPanelState extends State<EnhancedTableSettingsPanel> {
  // Migration removed - columns are managed in-canvas
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // INFO: Column management removed - use in-canvas controls instead
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: Colors.blue[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Use the "Add Column" button in the table canvas to add and manage columns',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[900],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 32),

          // SECTION 1: Row Configuration
          _buildRowConfigurationSection(),

          const Divider(height: 32),

          // SECTION 2: Display Options
          _buildDisplayOptionsSection(),

          const Divider(height: 32),

          // SECTION 3: Validation Rules
          _buildValidationSection(),
        ],
      ),
    );
  }

  // Column Configuration Section - REMOVED
  // Use in-canvas "Add Column" button and column headers for all column management

  /// SECTION 1: Row Configuration
  Widget _buildRowConfigurationSection() {
    return ExpandableSection(
      title: 'Row Configuration',
      icon: Icons.table_rows,
      initiallyExpanded: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Min/Max Rows
          const Text(
            'Row Limits',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _TableSettingsTextField(
                  initialValue: (widget.field.props['minRows'] ?? 1).toString(),
                  labelText: 'Min Rows',
                  helperText: 'Minimum required',
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final intValue = int.tryParse(value);
                    if (intValue != null && intValue >= 1 && intValue <= 100) {
                      widget.provider.updateField(
                        widget.field.id,
                        {'minRows': intValue},
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TableSettingsTextField(
                  initialValue: (widget.field.props['maxRows'] ?? 50).toString(),
                  labelText: 'Max Rows',
                  helperText: 'Maximum allowed',
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final intValue = int.tryParse(value);
                    if (intValue != null && intValue >= 1 && intValue <= 500) {
                      widget.provider.updateField(
                        widget.field.id,
                        {'maxRows': intValue},
                      );
                    }
                  },
                ),
              ),
            ],
          ),

          const Divider(height: 24),

          // Row Permissions
          const Text(
            'Row Permissions',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          SwitchListTile(
            title: const Text('Allow adding rows'),
            value: widget.field.props['allowAddRows'] ?? true,
            onChanged: (value) {
              widget.provider.updateField(
                widget.field.id,
                {'allowAddRows': value},
              );
            },
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),

          SwitchListTile(
            title: const Text('Allow deleting rows'),
            value: widget.field.props['allowDeleteRows'] ?? true,
            onChanged: (value) {
              widget.provider.updateField(
                widget.field.id,
                {'allowDeleteRows': value},
              );
            },
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),

          SwitchListTile(
            title: const Text('Allow reordering rows'),
            value: widget.field.props['allowReorderRows'] ?? true,
            onChanged: (value) {
              widget.provider.updateField(
                widget.field.id,
                {'allowReorderRows': value},
              );
            },
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ],
      ),
    );
  }

  /// SECTION 3: Display Options
  Widget _buildDisplayOptionsSection() {
    return ExpandableSection(
      title: 'Display Options',
      icon: Icons.visibility,
      initiallyExpanded: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: const Text('Show row numbers'),
            value: widget.field.props['showRowNumbers'] ?? true,
            onChanged: (value) {
              widget.provider.updateField(
                widget.field.id,
                {'showRowNumbers': value},
              );
            },
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),

          SwitchListTile(
            title: const Text('Show serial numbers column'),
            subtitle: const Text(
              'Auto-numbered column at the start',
              style: TextStyle(fontSize: 11),
            ),
            value: widget.field.props['showSerialNumbers'] ?? false,
            onChanged: (value) {
              widget.provider.updateField(
                widget.field.id,
                {'showSerialNumbers': value},
              );
            },
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),

          SwitchListTile(
            title: const Text('Zebra striping'),
            subtitle: const Text(
              'Alternating row colors',
              style: TextStyle(fontSize: 11),
            ),
            value: widget.field.props['striped'] ?? true,
            onChanged: (value) {
              widget.provider.updateField(
                widget.field.id,
                {'striped': value},
              );
            },
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),

          SwitchListTile(
            title: const Text('Show borders'),
            value: widget.field.props['bordered'] ?? true,
            onChanged: (value) {
              widget.provider.updateField(
                widget.field.id,
                {'bordered': value},
              );
            },
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),

          SwitchListTile(
            title: const Text('Compact spacing'),
            value: widget.field.props['compact'] ?? false,
            onChanged: (value) {
              widget.provider.updateField(
                widget.field.id,
                {'compact': value},
              );
            },
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),

          SwitchListTile(
            title: const Text('Allow export to CSV'),
            value: widget.field.props['exportable'] ?? true,
            onChanged: (value) {
              widget.provider.updateField(
                widget.field.id,
                {'exportable': value},
              );
            },
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),

          const Divider(height: 24),

          // Scroll Options
          const Text(
            'Scroll Options',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          _TableSettingsTextField(
            initialValue: widget.field.props['maxHeight']?.toString() ?? '',
            labelText: 'Max Height (px)',
            helperText: 'Maximum table height before vertical scroll',
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final intValue = value.isEmpty ? null : int.tryParse(value);
              widget.provider.updateField(
                widget.field.id,
                {'maxHeight': intValue},
              );
            },
          ),

          const SizedBox(height: 12),

          SwitchListTile(
            title: const Text('Enable horizontal scroll'),
            subtitle: const Text(
              'Allow scrolling when columns exceed width',
              style: TextStyle(fontSize: 11),
            ),
            value: widget.field.props['horizontalScroll'] ?? true,
            onChanged: (value) {
              widget.provider.updateField(
                widget.field.id,
                {'horizontalScroll': value},
              );
            },
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ],
      ),
    );
  }

  /// SECTION 4: Validation
  Widget _buildValidationSection() {
    return ExpandableSection(
      title: 'Table Validation',
      icon: Icons.rule,
      initiallyExpanded: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: const Text('Require complete rows'),
            subtitle: const Text(
              'All columns must be filled in each row',
              style: TextStyle(fontSize: 11),
            ),
            value: widget.field.props['requireCompleteRows'] ?? false,
            onChanged: (value) {
              widget.provider.updateField(
                widget.field.id,
                {'requireCompleteRows': value},
              );
            },
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),

          SwitchListTile(
            title: const Text('Validate on submit'),
            subtitle: const Text(
              'Check all validations when form is submitted',
              style: TextStyle(fontSize: 11),
            ),
            value: widget.field.props['validateOnSubmit'] ?? true,
            onChanged: (value) {
              widget.provider.updateField(
                widget.field.id,
                {'validateOnSubmit': value},
              );
            },
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ],
      ),
    );
  }

  // Helper methods removed - column management now done in-canvas
  // _getColumnTypeLabel, _normalizeWidthValue no longer needed
}

/// Stateful TextField for Table Settings
/// Prevents cursor reset by maintaining its own controller
class _TableSettingsTextField extends StatefulWidget {
  final String initialValue;
  final String labelText;
  final String? helperText;
  final TextInputType? keyboardType;
  final Function(String) onChanged;

  const _TableSettingsTextField({
    required this.initialValue,
    required this.labelText,
    this.helperText,
    this.keyboardType,
    required this.onChanged,
  });

  @override
  State<_TableSettingsTextField> createState() => _TableSettingsTextFieldState();
}

class _TableSettingsTextFieldState extends State<_TableSettingsTextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isInternalUpdate = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controller = TextEditingController(text: widget.initialValue);
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (!_isInternalUpdate) {
      widget.onChanged(_controller.text);
    }
  }

  @override
  void didUpdateWidget(_TableSettingsTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Only update if value changed and field not focused
    if (widget.initialValue != oldWidget.initialValue && 
        widget.initialValue != _controller.text &&
        !_focusNode.hasFocus) {
      _isInternalUpdate = true;
      _controller.text = widget.initialValue;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: widget.initialValue.length),
      );
      _isInternalUpdate = false;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      keyboardType: widget.keyboardType,
      decoration: InputDecoration(
        labelText: widget.labelText,
        helperText: widget.helperText,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }
}
