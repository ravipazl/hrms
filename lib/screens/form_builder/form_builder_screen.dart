import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/form_builder_provider.dart';
import '../../widgets/form_builder/builder_components/field_sidebar.dart';
import '../../widgets/form_builder/builder_components/interactive_form_canvas.dart';
import '../../widgets/form_builder/builder_components/enhanced_field_properties_panel.dart';
import '../../widgets/form_builder/builder_components/toolbar_widget.dart';
import '../../widgets/form_builder/header/header_settings_panel.dart';
import '../../widgets/form_builder/header/form_header_preview.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/form_builder/preview/form_preview_screen.dart'; 

/// Main Form Builder Screen - Drag & Drop Form Designer
class FormBuilderScreen extends StatelessWidget {
  final String? templateId;

  const FormBuilderScreen({super.key, this.templateId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final provider = FormBuilderProvider();
        if (templateId != null) {
          // Load template if ID provided
          Future.microtask(() => provider.loadTemplate(templateId!));
        }
        return provider;
      },
      child: const _FormBuilderContent(),
    );
  }
}

class _FormBuilderContent extends StatelessWidget {
  const _FormBuilderContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Consumer<FormBuilderProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: LoadingWidget());
          }

          return Column(
            children: [
              // Top Toolbar
              const ToolbarWidget(),

              // Main Content Area
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Sidebar - Field Library
                    Container(
                      width: 280,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          right: BorderSide(color: Colors.grey[300]!),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(2, 0),
                          ),
                        ],
                      ),
                      child: const FieldSidebar(),
                    ),

                    // Center - Form Canvas
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        child: provider.mode == 'builder'
                        ? const InteractiveFormCanvas()
                        : _buildPreviewMode(context, provider),
                      ),
                    ),

                    // Right Panel - Field Properties or Form Properties
                    if (provider.mode == 'builder')
                      Container(
                        width: 320,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            left: BorderSide(color: Colors.grey[300]!),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(-2, 0),
                            ),
                          ],
                        ),
                        child: provider.selectedField != null
                            ? const EnhancedFieldPropertiesPanel()
                            : _buildFormPropertiesPanel(context, provider),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPreviewMode(BuildContext context, FormBuilderProvider provider) {
    // Use the new functional preview screen
    return FormPreviewScreen(
      fields: provider.fields,
      formTitle: provider.formTitle,
      formDescription: provider.formDescription,
      headerConfig: provider.headerConfig,
      onSubmit: (formData) {
        // Handle form submission
        debugPrint('Form submitted in preview: $formData');
      },
    );
  }

  Widget _buildFormPropertiesPanel(BuildContext context, FormBuilderProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Form Properties',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Header Preview Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.preview, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Header Preview',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FormHeaderPreview(
                  formTitle: provider.formTitle,
                  formDescription: provider.formDescription,
                  headerConfig: provider.headerConfig,
                  mode: 'builder',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Form Title
          TextField(
            decoration: const InputDecoration(
              labelText: 'Form Title',
              border: OutlineInputBorder(),
            ),
            controller: TextEditingController(text: provider.formTitle),
            onChanged: provider.updateFormTitle,
          ),
          const SizedBox(height: 16),

          // Form Description
          TextField(
            decoration: const InputDecoration(
              labelText: 'Form Description',
              border: OutlineInputBorder(),
            ),
            controller: TextEditingController(text: provider.formDescription),
            onChanged: provider.updateFormDescription,
            maxLines: 3,
          ),
          const SizedBox(height: 24),

          // Header Settings Button - ENHANCED
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[600]!, Colors.blue[400]!],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.settings, color: Colors.white, size: 32),
                const SizedBox(height: 8),
                const Text(
                  'Header Configuration',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Full customization with logo, styling & more',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Open Header Settings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue[700],
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    // Pass the provider value to the dialog
                    showDialog(
                      context: context,
                      builder: (dialogContext) => ChangeNotifierProvider.value(
                        value: provider,
                        child: Dialog(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 900,
                              maxHeight: 700,
                            ),
                            child: const HeaderSettingsPanel(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Form Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Form Statistics',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[900],
                  ),
                ),
                const SizedBox(height: 8),
                Text('Fields: ${provider.fields.length}'),
                if (provider.currentTemplate != null) ...[
                  Text('Views: ${provider.currentTemplate!.viewCount}'),
                  Text('Submissions: ${provider.currentTemplate!.submissionCount}'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
