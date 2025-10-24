import 'package:flutter/material.dart';
import '../../services/form_builder_api_service.dart';
import '../../models/form_builder/form_template.dart';
import 'submission_list_screen.dart';

/// Add this mixin to your FormListScreen State class
/// This adds submission viewing functionality to your form list
mixin SubmissionIntegration {
  
  /// Navigate to submission list for a template
  void viewSubmissions(BuildContext context, FormTemplate template, FormBuilderAPIService apiService) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubmissionListScreen(
          templateId: template.id,
          apiService: apiService,
        ),
      ),
    );
  }

  /// Build submissions button for form card
  Widget buildSubmissionsButton({
    required BuildContext context,
    required FormTemplate template,
    required FormBuilderAPIService apiService,
  }) {
    return IconButton(
      icon: Badge(
        label: Text('${template.submissionCount}'),
        isLabelVisible: template.submissionCount > 0,
        child: const Icon(Icons.list_alt),
      ),
      onPressed: () => viewSubmissions(context, template, apiService),
      tooltip: 'View Submissions (${template.submissionCount})',
    );
  }

  /// Show quick submission stats dialog
  Future<void> showSubmissionStats(
    BuildContext context,
    FormTemplate template,
    FormBuilderAPIService apiService,
  ) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Load submissions
      final submissions = await apiService.getSubmissions(template.id);
      
      if (!context.mounted) return;
      
      // Close loading
      Navigator.pop(context);

      // Calculate stats
      final pending = submissions.where((s) => s.status == 'pending').length;
      final processed = submissions.where((s) => s.status == 'processed').length;
      final failed = submissions.where((s) => s.status == 'failed').length;

      // Show stats dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(template.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StatRow(
                icon: Icons.pending,
                label: 'Pending',
                value: '$pending',
                color: Colors.orange,
              ),
              const SizedBox(height: 8),
              _StatRow(
                icon: Icons.check_circle,
                label: 'Processed',
                value: '$processed',
                color: Colors.green,
              ),
              const SizedBox(height: 8),
              _StatRow(
                icon: Icons.error,
                label: 'Failed',
                value: '$failed',
                color: Colors.red,
              ),
              const Divider(height: 24),
              _StatRow(
                icon: Icons.assignment,
                label: 'Total',
                value: '${submissions.length}',
                color: Colors.blue,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                viewSubmissions(context, template, apiService);
              },
              child: const Text('View All'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      
      // Close loading if still showing
      Navigator.of(context, rootNavigator: true).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading submissions: $e')),
      );
    }
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Example: How to use in your FormListScreen
/// 
/// class _FormListScreenState extends State<FormListScreen> with SubmissionIntegration {
///   late FormBuilderAPIService _apiService;
/// 
///   @override
///   void initState() {
///     super.initState();
///     _apiService = FormBuilderAPIService(AuthService());
///   }
/// 
///   Widget _buildTemplateCard(FormTemplate template) {
///     return Card(
///       child: ListTile(
///         title: Text(template.title),
///         subtitle: Text('${template.submissionCount} submissions'),
///         trailing: Row(
///           mainAxisSize: MainAxisSize.min,
///           children: [
///             // Your existing buttons (edit, delete, etc.)
///             IconButton(
///               icon: Icon(Icons.edit),
///               onPressed: () => editTemplate(template),
///             ),
///             
///             // NEW: Add submission button
///             buildSubmissionsButton(
///               context: context,
///               template: template,
///               apiService: _apiService,
///             ),
///           ],
///         ),
///       ),
///     );
///   }
/// }
