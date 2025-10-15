import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/form_builder_provider.dart';
 
/// Toolbar Widget - Top action bar with save, preview, export
class ToolbarWidget extends StatelessWidget {
  const ToolbarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FormBuilderProvider>(
      builder: (context, provider, _) {
        return Container(
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Back Button
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Back',
              ),
              const SizedBox(width: 16),

              // Form Title (Editable)
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Untitled Form',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  ),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  controller: TextEditingController(text: provider.formTitle),
                  onChanged: provider.updateFormTitle,
                ),
              ),

              // Spacer
              const SizedBox(width: 16),

              // Undo/Redo
              IconButton(
                icon: const Icon(Icons.undo),
                onPressed: provider.canUndo ? provider.undo : null,
                tooltip: 'Undo',
              ),
              IconButton(
                icon: const Icon(Icons.redo),
                onPressed: provider.canRedo ? provider.redo : null,
                tooltip: 'Redo',
              ),

              const VerticalDivider(),

              // Mode Toggle
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'builder',
                    label: Text('Builder'),
                    icon: Icon(Icons.edit, size: 18),
                  ),
                  ButtonSegment(
                    value: 'preview',
                    label: Text('Preview'),
                    icon: Icon(Icons.visibility, size: 18),
                  ),
                ],
                selected: {provider.mode},
                onSelectionChanged: (Set<String> selection) {
                  provider.setMode(selection.first);
                },
              ),

              const SizedBox(width: 16),

              // Save Status
              if (provider.isSaving)
                const Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Saving...'),
                  ],
                )
              else if (provider.hasUnsavedChanges)
                Text(
                  'Unsaved changes',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                  ),
                )
              else if (!provider.isNewForm)
                Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
                    const SizedBox(width: 4),
                    const Text(
                      'Saved',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),

              const SizedBox(width: 16),

              // Save Button
              ElevatedButton.icon(
                onPressed: provider.isSaving
                    ? null
                    : () async {
                        final success = await provider.saveTemplate();
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Form saved successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else if (!success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to save: ${provider.error}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.save, size: 18),
                label: const Text('Save'),
              ),

              const SizedBox(width: 8),

              // More Actions
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                tooltip: 'More Actions',
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.download, size: 18),
                        SizedBox(width: 8),
                        Text('Export JSON'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'import',
                    child: Row(
                      children: [
                        Icon(Icons.upload, size: 18),
                        SizedBox(width: 8),
                        Text('Import JSON'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'reset',
                    child: Row(
                      children: [
                        Icon(Icons.refresh, size: 18),
                        SizedBox(width: 8),
                        Text('Reset Form'),
                      ],
                    ),
                  ),
                  if (!provider.isNewForm)
                    const PopupMenuItem(
                      value: 'preview_public',
                      child: Row(
                        children: [
                          Icon(Icons.open_in_new, size: 18),
                          SizedBox(width: 8),
                          Text('Preview Public Form'),
                        ],
                      ),
                    ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'export':
                      _exportForm(context, provider);
                      break;
                    case 'import':
                      _importForm(context, provider);
                      break;
                    case 'reset':
                      _resetForm(context, provider);
                      break;
                    case 'preview_public':
                      _previewPublic(context, provider);
                      break;
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _exportForm(BuildContext context, FormBuilderProvider provider) {
    final json = provider.exportForm();
    // TODO: Implement file download
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export functionality coming soon')),
    );
  }

  void _importForm(BuildContext context, FormBuilderProvider provider) {
    // TODO: Implement file picker and import
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Import functionality coming soon')),
    );
  }

  Future<void> _resetForm(BuildContext context, FormBuilderProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Form'),
        content: const Text(
          'Are you sure you want to reset this form? All unsaved changes will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      provider.resetForm();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Form reset successfully')),
        );
      }
    }
  }

  void _previewPublic(BuildContext context, FormBuilderProvider provider) {
    if (provider.currentTemplate != null) {
      // TODO: Open public form URL
      final url = provider.currentTemplate!.getPublicFormUrl('http://127.0.0.1:5173');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Public URL: $url')),
      );
    }
  }
}
