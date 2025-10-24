import 'package:flutter/material.dart';
import '../../services/form_builder_api_service.dart';
import '../../services/auth_service.dart';
import '../../models/form_builder/form_template.dart';
import 'submission_list_screen.dart';
import 'submission_integration.dart';

/// COMPLETE INTEGRATION EXAMPLE
/// This shows the full flow: Create Form → Preview → Submit → View Submissions

class CompleteFormFlowExample extends StatefulWidget {
  const CompleteFormFlowExample({super.key});

  @override
  State<CompleteFormFlowExample> createState() => _CompleteFormFlowExampleState();
}

class _CompleteFormFlowExampleState extends State<CompleteFormFlowExample> with SubmissionIntegration {
  late FormBuilderAPIService _apiService;
  List<FormTemplate> _templates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _apiService = FormBuilderAPIService(AuthService());
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);
    try {
      final templates = await _apiService.getTemplates();
      setState(() {
        _templates = templates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Forms'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTemplates,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _templates.isEmpty
              ? _buildEmptyState()
              : _buildTemplateList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to your form builder
          // After creating form, reload templates
          _loadTemplates();
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Form'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 100, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No forms yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first form to get started',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateList() {
    return RefreshIndicator(
      onRefresh: _loadTemplates,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _templates.length,
        itemBuilder: (context, index) {
          final template = _templates[index];
          return _buildTemplateCard(template);
        },
      ),
    );
  }

  Widget _buildTemplateCard(FormTemplate template) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showTemplateOptions(template),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.description, color: Colors.blue.shade700),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (template.description?.isNotEmpty ?? false)
                          Text(
                            template.description!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  _buildStatusChip(template.status),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStat(
                    icon: Icons.list,
                    label: 'Fields',
                    value: '${template.fieldsCount}',
                  ),
                  _buildStat(
                    icon: Icons.assignment_turned_in,
                    label: 'Submissions',
                    value: '${template.submissionCount}',
                    color: Colors.green,
                  ),
                  _buildStat(
                    icon: Icons.visibility,
                    label: 'Views',
                    value: '${template.viewCount}',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Edit Button
                  TextButton.icon(
                    onPressed: () {
                      // Navigate to form builder in edit mode
                      // Navigator.push(context, MaterialPageRoute(...));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Edit form')),
                      );
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                  ),
                  const SizedBox(width: 8),
                  
                  // Preview Button
                  TextButton.icon(
                    onPressed: () {
                      // Navigate to preview/fill form
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Preview form')),
                      );
                    },
                    icon: const Icon(Icons.preview, size: 18),
                    label: const Text('Preview'),
                  ),
                  const SizedBox(width: 8),
                  
                  // View Submissions Button - THIS IS THE KEY!
                  ElevatedButton.icon(
                    onPressed: () => viewSubmissions(context, template, _apiService),
                    icon: Badge(
                      label: Text('${template.submissionCount}'),
                      isLabelVisible: template.submissionCount > 0,
                      child: const Icon(Icons.list_alt, size: 18),
                    ),
                    label: const Text('Submissions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'published':
        color = Colors.green;
        break;
      case 'draft':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.blue.shade700, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  void _showTemplateOptions(FormTemplate template) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Form'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to edit
              },
            ),
            ListTile(
              leading: const Icon(Icons.preview),
              title: const Text('Preview Form'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to preview
              },
            ),
            ListTile(
              leading: Badge(
                label: Text('${template.submissionCount}'),
                isLabelVisible: template.submissionCount > 0,
                child: const Icon(Icons.list_alt),
              ),
              title: const Text('View Submissions'),
              subtitle: Text('${template.submissionCount} submissions'),
              onTap: () {
                Navigator.pop(context);
                viewSubmissions(context, template, _apiService);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('View Statistics'),
              onTap: () {
                Navigator.pop(context);
                showSubmissionStats(context, template, _apiService);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Form'),
              onTap: () {
                Navigator.pop(context);
                _shareForm(template);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red.shade700),
              title: Text('Delete Form', style: TextStyle(color: Colors.red.shade700)),
              onTap: () {
                Navigator.pop(context);
                _deleteForm(template);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _shareForm(FormTemplate template) {
    final publicUrl = _apiService.generatePublicFormUrl(template.id);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Form'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Public Form URL:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                publicUrl,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // Copy to clipboard logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('URL copied to clipboard')),
              );
              Navigator.pop(context);
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy URL'),
          ),
        ],
      ),
    );
  }

  void _deleteForm(FormTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Form'),
        content: Text('Are you sure you want to delete "${template.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                await _apiService.deleteTemplate(template.id);
                _loadTemplates();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Form deleted successfully')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// MINIMAL INTEGRATION - Just add this to your existing form list screen
/// 
/// 1. Add import:
///    import 'submission_list_screen.dart';
///    import '../../services/form_builder_api_service.dart';
///
/// 2. Add API service to your State class:
///    late FormBuilderAPIService _apiService;
///    
///    @override
///    void initState() {
///      super.initState();
///      _apiService = FormBuilderAPIService(AuthService());
///    }
///
/// 3. Add button to your form card:
///    ElevatedButton.icon(
///      onPressed: () {
///        Navigator.push(
///          context,
///          MaterialPageRoute(
///            builder: (context) => SubmissionListScreen(
///              templateId: template.id,
///              apiService: _apiService,
///            ),
///          ),
///        );
///      },
///      icon: const Icon(Icons.list_alt),
///      label: const Text('View Submissions'),
///    )
///
/// That's it! Users can now click this button to see all submissions for that form.
