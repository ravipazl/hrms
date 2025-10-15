import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../../models/form_builder/enhanced_header_config.dart';
import '../../../providers/form_builder_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

/// Complete Header Settings Panel with React-style tabs and features
class HeaderSettingsPanel extends StatefulWidget {
  const HeaderSettingsPanel({super.key});

  @override
  State<HeaderSettingsPanel> createState() => _HeaderSettingsPanelState();
}

class _HeaderSettingsPanelState extends State<HeaderSettingsPanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FormBuilderProvider>(
      builder: (context, provider, _) {
        return Container(
          width: 900,
          height: 700,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.settings, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Form Header Configuration',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Tab Navigation
              Container(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.blue[700],
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: Colors.blue[700],
                  tabs: const [
                    Tab(icon: Icon(Icons.settings, size: 16), text: 'Basic'),
                    Tab(icon: Icon(Icons.palette, size: 16), text: 'Styling'),
                    Tab(icon: Icon(Icons.view_quilt, size: 16), text: 'Layout'),
                    Tab(icon: Icon(Icons.add_circle_outline, size: 16), text: 'Custom'),
                  ],
                ),
              ),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _BasicSettingsTab(provider: provider),
                    _StylingSettingsTab(provider: provider),
                    _LayoutSettingsTab(provider: provider),
                    _CustomFieldsTab(provider: provider),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Basic Settings Tab
class _BasicSettingsTab extends StatelessWidget {
  final FormBuilderProvider provider;

  const _BasicSettingsTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final headerConfig = provider.headerConfig;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Form & Header Settings'),
          const SizedBox(height: 16),
          
          _TextField(
            label: 'Form Title',
            value: provider.formTitle,
            onChanged: provider.updateFormTitle,
          ),
          const SizedBox(height: 16),
          
          _TextAreaField(
            label: 'Form Description',
            value: provider.formDescription,
            onChanged: provider.updateFormDescription,
          ),
          const SizedBox(height: 24),
          
          _SwitchTile(
            title: 'Enable Form Header',
            value: headerConfig.enabled,
            onChanged: (value) {
              provider.updateHeaderConfig(headerConfig.copyWith(enabled: value));
            },
          ),
          
          if (headerConfig.enabled) ...[
            const Divider(height: 32),
            const _SectionTitle('Logo Configuration'),
            const SizedBox(height: 16),
            
            _SwitchTile(
              title: 'Show Logo',
              value: headerConfig.logo.enabled,
              onChanged: (value) {
                provider.updateLogoConfig(headerConfig.logo.copyWith(enabled: value));
              },
            ),
            
            if (headerConfig.logo.enabled) ...[
              const SizedBox(height: 16),
              _LogoUploadSection(provider: provider, headerConfig: headerConfig),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _EditableTextField(
                      key: const ValueKey('logo_width'),
                      label: 'Logo Width',
                      initialValue: headerConfig.logo.width,
                      placeholder: 'e.g., 200, 200px, auto',
                      onChanged: (value) {
                        String finalValue = value;
                        if (value.isNotEmpty && value != 'auto' && !value.contains('px')) {
                          final numValue = double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), ''));
                          if (numValue != null) finalValue = '${numValue}px';
                        }
                        provider.updateLogoConfig(headerConfig.logo.copyWith(width: finalValue));
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _EditableTextField(
                      key: const ValueKey('logo_height'),
                      label: 'Logo Height',
                      initialValue: headerConfig.logo.height,
                      placeholder: 'e.g., 80, 80px, auto',
                      onChanged: (value) {
                        String finalValue = value;
                        if (value.isNotEmpty && value != 'auto' && !value.contains('px')) {
                          final numValue = double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), ''));
                          if (numValue != null) finalValue = '${numValue}px';
                        }
                        provider.updateLogoConfig(headerConfig.logo.copyWith(height: finalValue));
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _QuickSizeButton(label: 'Small (100x50)', onPressed: () {
                    provider.updateLogoConfig(headerConfig.logo.copyWith(width: '100px', height: '50px'));
                  }),
                  _QuickSizeButton(label: 'Medium (200x100)', onPressed: () {
                    provider.updateLogoConfig(headerConfig.logo.copyWith(width: '200px', height: '100px'));
                  }),
                  _QuickSizeButton(label: 'Large (300x150)', onPressed: () {
                    provider.updateLogoConfig(headerConfig.logo.copyWith(width: '300px', height: '150px'));
                  }),
                  _QuickSizeButton(label: 'Auto', onPressed: () {
                    provider.updateLogoConfig(headerConfig.logo.copyWith(width: 'auto', height: 'auto'));
                  }),
                ],
              ),
              const SizedBox(height: 16),
              
              _DropdownField(
                label: 'Logo Position',
                value: headerConfig.logo.position,
                items: const [
                  DropdownMenuItem(value: 'left', child: Text('Left')),
                  DropdownMenuItem(value: 'center', child: Text('Center')),
                  DropdownMenuItem(value: 'right', child: Text('Right')),
                ],
                onChanged: (value) {
                  provider.updateLogoConfig(headerConfig.logo.copyWith(position: value));
                },
              ),
            ],
            
            const Divider(height: 32),
            const _SectionTitle('Title Configuration'),
            const SizedBox(height: 16),
            
            _SwitchTile(
              title: 'Show Title',
              value: headerConfig.title.visible,
              onChanged: (value) {
                provider.updateTitleConfig(headerConfig.title.copyWith(visible: value));
              },
            ),
            
            if (headerConfig.title.visible) ...[
              const SizedBox(height: 16),
              _DropdownField(
                label: 'Title Style',
                value: headerConfig.title.style,
                items: const [
                  DropdownMenuItem(value: 'h1', child: Text('Heading 1 (Largest)')),
                  DropdownMenuItem(value: 'h2', child: Text('Heading 2')),
                  DropdownMenuItem(value: 'h3', child: Text('Heading 3')),
                  DropdownMenuItem(value: 'h4', child: Text('Heading 4')),
                  DropdownMenuItem(value: 'h5', child: Text('Heading 5')),
                  DropdownMenuItem(value: 'h6', child: Text('Heading 6 (Smallest)')),
                ],
                onChanged: (value) {
                  provider.updateTitleConfig(headerConfig.title.copyWith(style: value));
                },
              ),
              const SizedBox(height: 16),
              _AlignmentButtons(
                label: 'Title Alignment',
                value: headerConfig.title.align,
                onChanged: (value) {
                  provider.updateTitleConfig(headerConfig.title.copyWith(align: value));
                },
              ),
            ],
            
            const Divider(height: 32),
            const _SectionTitle('Description Configuration'),
            const SizedBox(height: 16),
            
            _SwitchTile(
              title: 'Show Description',
              value: headerConfig.description.visible,
              onChanged: (value) {
                provider.updateDescriptionConfig(headerConfig.description.copyWith(visible: value));
              },
            ),
            
            if (headerConfig.description.visible) ...[
              const SizedBox(height: 16),
              _AlignmentButtons(
                label: 'Description Alignment',
                value: headerConfig.description.align,
                onChanged: (value) {
                  provider.updateDescriptionConfig(headerConfig.description.copyWith(align: value));
                },
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// Styling Settings Tab
class _StylingSettingsTab extends StatelessWidget {
  final FormBuilderProvider provider;

  const _StylingSettingsTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final styling = provider.headerConfig.styling;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Header Styling', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),

          const _SectionTitle('Background'),
          const SizedBox(height: 12),
          _DropdownField(
            label: 'Background Type',
            value: styling.backgroundType,
            items: const [
              DropdownMenuItem(value: 'solid', child: Text('Solid')),
              DropdownMenuItem(value: 'gradient', child: Text('Gradient')),
              DropdownMenuItem(value: 'none', child: Text('Transparent')),
            ],
            onChanged: (value) {
              provider.updateStylingConfig(styling.copyWith(backgroundType: value));
            },
          ),
          if (styling.backgroundType == 'solid') ...[
            const SizedBox(height: 16),
            _ColorPickerField(
              label: 'Background Color',
              color: styling.backgroundColor,
              onChanged: (color) {
                provider.updateStylingConfig(styling.copyWith(backgroundColor: color));
              },
            ),
          ],
          if (styling.backgroundType == 'gradient') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ColorPickerField(
                    label: 'Start Color',
                    color: styling.gradientStart ?? '#ffffff',
                    onChanged: (color) {
                      provider.updateStylingConfig(styling.copyWith(gradientStart: color));
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ColorPickerField(
                    label: 'End Color',
                    color: styling.gradientEnd ?? '#f0f0f0',
                    onChanged: (color) {
                      provider.updateStylingConfig(styling.copyWith(gradientEnd: color));
                    },
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 24),
          const _SectionTitle('Typography'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ColorPickerField(
                  label: 'Title Color',
                  color: styling.titleColor,
                  onChanged: (color) {
                    provider.updateStylingConfig(styling.copyWith(titleColor: color));
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ColorPickerField(
                  label: 'Description Color',
                  color: styling.descriptionColor,
                  onChanged: (color) {
                    provider.updateStylingConfig(styling.copyWith(descriptionColor: color));
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const _SectionTitle('Spacing'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TextField(
                  label: 'Padding',
                  value: styling.padding,
                  placeholder: 'e.g., 20px',
                  onChanged: (value) {
                    provider.updateStylingConfig(styling.copyWith(padding: value));
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TextField(
                  label: 'Margin',
                  value: styling.margin,
                  placeholder: 'e.g., 0 0 20px 0',
                  onChanged: (value) {
                    provider.updateStylingConfig(styling.copyWith(margin: value));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Layout Settings Tab
class _LayoutSettingsTab extends StatelessWidget {
  final FormBuilderProvider provider;

  const _LayoutSettingsTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final layout = provider.headerConfig.layout;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Layout & Structure', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),

          _DropdownField(
            label: 'Header Layout',
            value: layout.type,
            items: const [
              DropdownMenuItem(value: 'stacked', child: Text('Stacked')),
              DropdownMenuItem(value: 'inline', child: Text('Inline')),
              DropdownMenuItem(value: 'centered', child: Text('Centered')),
              DropdownMenuItem(value: 'split', child: Text('Split')),
            ],
            onChanged: (value) {
              provider.updateLayoutConfig(layout.copyWith(type: value));
            },
          ),

          const SizedBox(height: 24),
          const _SectionTitle('Container Settings'),
          const SizedBox(height: 12),

          _TextField(
            label: 'Max Width',
            value: layout.maxWidth,
            placeholder: 'e.g., 1200px, 100%',
            onChanged: (value) {
              provider.updateLayoutConfig(layout.copyWith(maxWidth: value));
            },
          ),

          const SizedBox(height: 24),
          const _SectionTitle('Responsive Behavior'),
          const SizedBox(height: 12),

          _SwitchTile(
            title: 'Enable Responsive Design',
            value: layout.responsive,
            onChanged: (value) {
              provider.updateLayoutConfig(layout.copyWith(responsive: value));
            },
          ),
        ],
      ),
    );
  }
}

/// Custom Fields Tab
class _CustomFieldsTab extends StatelessWidget {
  final FormBuilderProvider provider;

  const _CustomFieldsTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final customFields = provider.headerConfig.customFields;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Custom Header Fields', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Field'),
                onPressed: () {
                  final newField = CustomHeaderField(
                    id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                    type: 'text',
                    label: 'Custom Field',
                    value: 'Custom Value',
                  );
                  provider.addCustomHeaderField(newField);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (customFields.isEmpty)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  Icon(Icons.add_box_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No custom fields yet', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            )
          else
            ...customFields.map((field) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Chip(label: Text(field.type.toUpperCase())),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                            onPressed: () => provider.removeCustomHeaderField(field.id),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _TextField(
                        label: 'Label',
                        value: field.label,
                        onChanged: (value) {
                          provider.updateCustomHeaderField(field.id, field.copyWith(label: value));
                        },
                      ),
                      const SizedBox(height: 12),
                      _TextField(
                        label: 'Value',
                        value: field.value,
                        onChanged: (value) {
                          provider.updateCustomHeaderField(field.id, field.copyWith(value: value));
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ============= HELPER WIDGETS =============

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600));
  }
}

class _TextField extends StatefulWidget {
  final String label;
  final String value;
  final String? placeholder;
  final Function(String) onChanged;

  const _TextField({required this.label, required this.value, this.placeholder, required this.onChanged});

  @override
  State<_TextField> createState() => _TextFieldState();
}

class _TextFieldState extends State<_TextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isInternalUpdate = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controller = TextEditingController(text: widget.value);
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (!_isInternalUpdate) {
      widget.onChanged(_controller.text);
    }
  }

  @override
  void didUpdateWidget(_TextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && widget.value != _controller.text && !_focusNode.hasFocus) {
      _isInternalUpdate = true;
      _controller.text = widget.value;
      _controller.selection = TextSelection.fromPosition(TextPosition(offset: widget.value.length));
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: widget.placeholder,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            isDense: true,
          ),
        ),
      ],
    );
  }
}

class _TextAreaField extends StatefulWidget {
  final String label;
  final String value;
  final Function(String) onChanged;

  const _TextAreaField({required this.label, required this.value, required this.onChanged});

  @override
  State<_TextAreaField> createState() => _TextAreaFieldState();
}

class _TextAreaFieldState extends State<_TextAreaField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isInternalUpdate = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controller = TextEditingController(text: widget.value);
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (!_isInternalUpdate) {
      widget.onChanged(_controller.text);
    }
  }

  @override
  void didUpdateWidget(_TextAreaField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && widget.value != _controller.text && !_focusNode.hasFocus) {
      _isInternalUpdate = true;
      _controller.text = widget.value;
      _controller.selection = TextSelection.fromPosition(TextPosition(offset: widget.value.length));
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.all(12), isDense: true),
          maxLines: 3,
        ),
      ],
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<DropdownMenuItem<String>> items;
  final Function(String) onChanged;

  const _DropdownField({required this.label, required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), isDense: true),
          items: items,
          onChanged: (newValue) {
            if (newValue != null) onChanged(newValue);
          },
        ),
      ],
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final bool value;
  final Function(bool) onChanged;

  const _SwitchTile({required this.title, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
        Switch(value: value, onChanged: onChanged, activeThumbColor: Colors.blue[700]),
      ],
    );
  }
}
 
class _AlignmentButtons extends StatelessWidget {
  final String label;
  final String value;
  final Function(String) onChanged;

  const _AlignmentButtons({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            _AlignButton(icon: Icons.format_align_left, isSelected: value == 'left', onTap: () => onChanged('left')),
            const SizedBox(width: 8),
            _AlignButton(icon: Icons.format_align_center, isSelected: value == 'center', onTap: () => onChanged('center')),
            const SizedBox(width: 8),
            _AlignButton(icon: Icons.format_align_right, isSelected: value == 'right', onTap: () => onChanged('right')),
          ],
        ),
      ],
    );
  }
}

class _AlignButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _AlignButton({required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[700] : Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 20, color: isSelected ? Colors.white : Colors.black54),
      ),
    );
  }
}

class _ColorPickerField extends StatelessWidget {
  final String label;
  final String color;
  final Function(String) onChanged;

  const _ColorPickerField({required this.label, required this.color, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final newColor = await showDialog<Color>(
              context: context,
              builder: (context) => _ColorPickerDialog(initialColor: _hexToColor(color)),
            );
            if (newColor != null) {
              onChanged(_colorToHex(newColor));
            }
          },
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: _hexToColor(color),
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                color.toUpperCase(),
                style: TextStyle(color: _getContrastColor(_hexToColor(color)), fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  Color _getContrastColor(Color color) {
    return color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }
}

class _ColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  const _ColorPickerDialog({required this.initialColor});

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late Color selectedColor;

  @override
  void initState() {
    super.initState();
    selectedColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pick a Color'),
      content: SingleChildScrollView(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: Colors.primaries.map((color) {
            return InkWell(
              onTap: () => setState(() => selectedColor = color),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  border: Border.all(
                    color: selectedColor == color ? Colors.black : Colors.transparent,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(context, selectedColor), child: const Text('Select')),
      ],
    );
  }
}

class _LogoUploadSection extends StatelessWidget {
  final FormBuilderProvider provider;
  final HeaderConfig headerConfig;

  const _LogoUploadSection({required this.provider, required this.headerConfig});

  Future<void> _pickImage(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        final Uint8List bytes = await image.readAsBytes();
        final String base64Image = base64Encode(bytes);
        final String dataUrl = 'data:image/${image.path.split('.').last};base64,$base64Image';
        
        provider.updateLogoConfig(headerConfig.logo.copyWith(
          enabled: true,
          src: dataUrl,
          alt: image.name,
          fileName: image.name,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          if (headerConfig.logo.src != null)
            Column(
              children: [
                Container(
                  constraints: const BoxConstraints(maxHeight: 100),
                  child: Image.memory(base64Decode(headerConfig.logo.src!.split(',')[1]), fit: BoxFit.contain),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                  label: const Text('Remove Logo', style: TextStyle(color: Colors.red)),
                  onPressed: () {
                    provider.updateLogoConfig(headerConfig.logo.copyWith(enabled: false, src: null));
                  },
                ),
              ],
            )
          else
            Column(
              children: [
                Icon(Icons.cloud_upload_outlined, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text('No logo uploaded', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.upload_file, size: 18),
            label: Text(headerConfig.logo.src != null ? 'Change Logo' : 'Upload Logo'),
            onPressed: () => _pickImage(context),
          ),
        ],
      ),
    );
  }
}

// ============= EDITABLE TEXT FIELD WITH PROPER CONTROLLER =============

class _EditableTextField extends StatefulWidget {
  final String label;
  final String initialValue;
  final String? placeholder;
  final Function(String) onChanged;

  const _EditableTextField({
    super.key,
    required this.label,
    required this.initialValue,
    this.placeholder,
    required this.onChanged,
  });

  @override
  State<_EditableTextField> createState() => _EditableTextFieldState();
}

class _EditableTextFieldState extends State<_EditableTextField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(_EditableTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue && _controller.text != widget.initialValue) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: widget.placeholder,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            isDense: true,
          ),
          onChanged: widget.onChanged,
        ),
      ],
    );
  }
}

class _QuickSizeButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _QuickSizeButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: const TextStyle(fontSize: 11)),
    );
  }
}
