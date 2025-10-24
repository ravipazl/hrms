/// Example usage of submission list and view screens
/// 
/// This file demonstrates how to integrate the submission screens
/// into your Flutter HRMS app

import 'package:flutter/material.dart';
import '../../services/form_builder_api_service.dart';
import '../../services/auth_service.dart';
import 'submission_list_screen.dart';

/// Example 1: Navigate to submission list from form list
/// 
/// Use this in your form list screen when user taps "View Submissions"
void navigateToSubmissionList(
  BuildContext context,
  String templateId,
  FormBuilderAPIService apiService,
) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => SubmissionListScreen(
        templateId: templateId,
        apiService: apiService,
      ),
    ),
  );
}

/// Example 2: Add "View Submissions" button to form card
/// 
/// Add this to your form template card widget
class FormTemplateCardWithSubmissions extends StatelessWidget {
  final String templateId;
  final String templateTitle;
  final int submissionCount;
  final FormBuilderAPIService apiService;

  const FormTemplateCardWithSubmissions({
    super.key,
    required this.templateId,
    required this.templateTitle,
    required this.submissionCount,
    required this.apiService,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(templateTitle),
        subtitle: Text('$submissionCount submissions'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Existing buttons...
            IconButton(
              icon: const Icon(Icons.list_alt),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SubmissionListScreen(
                      templateId: templateId,
                      apiService: apiService,
                    ),
                  ),
                );
              },
              tooltip: 'View Submissions',
            ),
          ],
        ),
      ),
    );
  }
}

/// Example 3: Initialize and use in your app
/// 
/// In your main app or screen initialization:
class SubmissionManagementExample extends StatefulWidget {
  const SubmissionManagementExample({super.key});

  @override
  State<SubmissionManagementExample> createState() =>
      _SubmissionManagementExampleState();
}

class _SubmissionManagementExampleState
    extends State<SubmissionManagementExample> {
  late FormBuilderAPIService _apiService;

  @override
  void initState() {
    super.initState();
    // Initialize API service
    final authService = AuthService();
    _apiService = FormBuilderAPIService(authService);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Form Management')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Example: Navigate to submissions for a specific form
            const exampleTemplateId = 'your-template-id-here';
            
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SubmissionListScreen(
                  templateId: exampleTemplateId,
                  apiService: _apiService,
                ),
              ),
            );
          },
          child: const Text('View Form Submissions'),
        ),
      ),
    );
  }
}

/// Example 4: API service methods you can use
/// 
/// Available methods from FormBuilderAPIService:
///
/// 1. Get submissions list:
/// ```dart
/// final submissions = await apiService.getSubmissions(
///   templateId,
///   filters: {
///     'status': 'pending',
///     'search': 'keyword',
///     'start_date': '2025-01-01',
///     'end_date': '2025-01-31',
///   },
/// );
/// ```
///
/// 2. Get single submission:
/// ```dart
/// final submission = await apiService.getSubmission(submissionId);
/// ```
///
/// 3. Get template details:
/// ```dart
/// final template = await apiService.getTemplate(templateId);
/// ```

/// Example 5: Custom submission handling
/// 
/// You can extend the screens or handle submissions differently:
class CustomSubmissionHandler {
  final FormBuilderAPIService apiService;

  CustomSubmissionHandler(this.apiService);

  /// Load and process submissions
  Future<void> processSubmissions(String templateId) async {
    try {
      // Get all submissions
      final submissions = await apiService.getSubmissions(templateId);
      
      // Filter pending submissions
      final pending = submissions.where((s) => s.status == 'pending').toList();
      
      print('Found ${pending.length} pending submissions');
      
      // Process each submission
      for (final submission in pending) {
        print('Processing submission: ${submission.id}');
        // Your custom logic here
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  /// Export submissions to CSV or other format
  Future<String> exportSubmissions(String templateId) async {
    try {
      final submissions = await apiService.getSubmissions(templateId);
      
      // Build CSV data
      final csv = StringBuffer();
      csv.writeln('ID,Submitted At,Status,Submitter');
      
      for (final sub in submissions) {
        csv.writeln('${sub.id},${sub.submittedAt},${sub.status},${sub.displayName}');
      }
      
      return csv.toString();
    } catch (e) {
      throw Exception('Export failed: $e');
    }
  }

  /// Get submission statistics
  Future<Map<String, int>> getStatistics(String templateId) async {
    try {
      final submissions = await apiService.getSubmissions(templateId);
      
      return {
        'total': submissions.length,
        'pending': submissions.where((s) => s.status == 'pending').length,
        'processed': submissions.where((s) => s.status == 'processed').length,
        'failed': submissions.where((s) => s.status == 'failed').length,
        'anonymous': submissions.where((s) => s.isAnonymous).length,
      };
    } catch (e) {
      throw Exception('Statistics failed: $e');
    }
  }
}

/// Example 6: Error handling
/// 
/// Both screens handle errors gracefully and show:
/// - Loading states
/// - Error messages with retry button
/// - Empty states
/// 
/// You can also catch errors when navigating:
void navigateWithErrorHandling(
  BuildContext context,
  String templateId,
  FormBuilderAPIService apiService,
) async {
  try {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubmissionListScreen(
          templateId: templateId,
          apiService: apiService,
        ),
      ),
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}

/// Example 7: Refresh data after submission
/// 
/// After user submits a form, refresh the submission list:
void handleFormSubmitThenViewSubmissions(
  BuildContext context,
  String templateId,
  FormBuilderAPIService apiService,
) async {
  // After form submission...
  
  // Navigate to submission list (it will auto-load)
  if (context.mounted) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SubmissionListScreen(
          templateId: templateId,
          apiService: apiService,
        ),
      ),
    );
  }
}

/// Example 8: Add to existing form list screen
/// 
/// Integration example for your existing form_list_screen.dart:
class FormListIntegrationExample extends StatelessWidget {
  final FormBuilderAPIService apiService;

  const FormListIntegrationExample({
    super.key,
    required this.apiService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Forms')),
      body: ListView.builder(
        itemCount: 10, // Your forms count
        itemBuilder: (context, index) {
          // Your existing form card
          return Card(
            child: ListTile(
              title: Text('Form Title $index'),
              subtitle: const Text('5 submissions'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Edit button (existing)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      // Your edit logic
                    },
                  ),
                  // NEW: View submissions button
                  IconButton(
                    icon: const Icon(Icons.list_alt),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SubmissionListScreen(
                            templateId: 'template-id-$index',
                            apiService: apiService,
                          ),
                        ),
                      );
                    },
                    tooltip: 'View Submissions',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Example 9: Add submission count badge
/// 
/// Show unread/new submission count:
class FormCardWithBadge extends StatelessWidget {
  final String templateId;
  final String title;
  final int submissionCount;
  final int newSubmissionCount;
  final FormBuilderAPIService apiService;

  const FormCardWithBadge({
    super.key,
    required this.templateId,
    required this.title,
    required this.submissionCount,
    required this.newSubmissionCount,
    required this.apiService,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text('$submissionCount total submissions'),
        trailing: Badge(
          label: Text('$newSubmissionCount'),
          isLabelVisible: newSubmissionCount > 0,
          child: IconButton(
            icon: const Icon(Icons.list_alt),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SubmissionListScreen(
                    templateId: templateId,
                    apiService: apiService,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Example 10: Filter submissions programmatically
/// 
/// Load submissions with specific filters:
Future<void> loadPendingSubmissions(
  String templateId,
  FormBuilderAPIService apiService,
) async {
  try {
    final submissions = await apiService.getSubmissions(
      templateId,
      filters: {
        'status': 'pending',
      },
    );
    
    print('Found ${submissions.length} pending submissions');
    
    // Process pending submissions
    for (final submission in submissions) {
      print('Pending: ${submission.id}');
    }
  } catch (e) {
    print('Error: $e');
  }
}

/// Example 11: Load submissions by date range
/// 
/// Get submissions from last 7 days:
Future<void> loadRecentSubmissions(
  String templateId,
  FormBuilderAPIService apiService,
) async {
  try {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    
    final submissions = await apiService.getSubmissions(
      templateId,
      filters: {
        'start_date': sevenDaysAgo.toIso8601String().split('T')[0],
        'end_date': now.toIso8601String().split('T')[0],
      },
    );
    
    print('Found ${submissions.length} submissions in last 7 days');
  } catch (e) {
    print('Error: $e');
  }
}

/// Example 12: Show submission summary
/// 
/// Display quick stats in a dialog:
void showSubmissionSummary(
  BuildContext context,
  String templateId,
  FormBuilderAPIService apiService,
) async {
  try {
    final submissions = await apiService.getSubmissions(templateId);
    
    final pending = submissions.where((s) => s.status == 'pending').length;
    final processed = submissions.where((s) => s.status == 'processed').length;
    final failed = submissions.where((s) => s.status == 'failed').length;
    
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submission Summary'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.pending, color: Colors.orange),
              title: const Text('Pending'),
              trailing: Text('$pending'),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Processed'),
              trailing: Text('$processed'),
            ),
            ListTile(
              leading: const Icon(Icons.error, color: Colors.red),
              title: const Text('Failed'),
              trailing: Text('$failed'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.summarize),
              title: const Text('Total'),
              trailing: Text('${submissions.length}'),
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SubmissionListScreen(
                    templateId: templateId,
                    apiService: apiService,
                  ),
                ),
              );
            },
            child: const Text('View All'),
          ),
        ],
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}
