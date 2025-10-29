import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../models/form_builder/form_submission.dart';
import '../../models/form_builder/form_template.dart';
import '../../models/form_builder/form_field.dart' as form_model;
import '../../services/form_builder_api_service.dart';
import '../../widgets/form_builder/header/form_header_preview.dart';
import '../../widgets/form_builder/submission_renderers/submission_field_renderer.dart';
import '../../services/api_config.dart';
/// Submission View Screen - Renders exactly like form preview but in read-only mode
/// Uses the same header and field layout as the form builder preview
class SubmissionViewScreen extends StatefulWidget {
  final String submissionId;
  final FormTemplate? template;
  final FormBuilderAPIService apiService;

  const SubmissionViewScreen({
    super.key,
    required this.submissionId,
    this.template,
    required this.apiService,
  });

  @override
  State<SubmissionViewScreen> createState() => _SubmissionViewScreenState();
}

class _SubmissionViewScreenState extends State<SubmissionViewScreen> {
  FormSubmission? _submission;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSubmission();
  }

  Future<void> _loadSubmission() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final submission = await widget.apiService.getSubmission(widget.submissionId);

      if (mounted) {
        setState(() {
          _submission = submission;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submission Details'),
        actions: [
          if (_submission != null) ...[
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: _downloadPDF,
              tooltip: 'Download PDF',
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'export') {
                  _exportData();
                }
              },
              itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'export',
                      child: Row(
                        children: [
                          Icon(Icons.download),
                          SizedBox(width: 8),
                          Text('Export JSON'),
                        ],
                      ),
                    ),
                  ],
            ),
          ],
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
        );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Error loading submission',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadSubmission,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_submission == null) {
      return const Center(child: Text('No submission data'));
    }

    // Use template from submission if available, fallback to widget.template
    final template = _submission!.template ?? widget.template;

    if (template == null) {
      return const Center(child: Text('Template information not available'));
    }

    if (template.reactFormData == null) {
      return const Center(child: Text('Template structure not available'));
    }

    final formData = template.reactFormData!;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status Banner
          _buildStatusBanner(),

          // Form Header - exactly like preview
          FormHeaderPreview(
            formTitle: formData.formTitle,
            formDescription: formData.formDescription,
            headerConfig: formData.headerConfig,
            mode: 'view', // Read-only mode
          ),

          // Form Fields - same grid layout as preview
          if (formData.fields.isEmpty)
            const Padding(
              padding: EdgeInsets.all(48.0),
              child: Center(
                child: Text(
                  'No fields in this form',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildGridLayout(formData.fields, _submission!.formData),
            ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// Build status banner at the top
  Widget _buildStatusBanner() {
    if (_submission == null) return const SizedBox.shrink();

    Color statusColor;
    IconData statusIcon;

    switch (_submission!.status.toLowerCase()) {
      case 'processed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'failed':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: statusColor.withOpacity(0.3)),
          ),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Submission Status: ${_submission!.status.toUpperCase()}',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Submitted on ${DateFormat('MMM dd, yyyy - hh:mm a').format(_submission!.submittedAt)}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                     fontSize: 12,
                     ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build fields with automatic grid layout - EXACTLY like preview
  Widget _buildGridLayout(
    List<form_model.FormField> fields,
    Map<String, dynamic> formData,
  ) {
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
          child: SubmissionFieldRenderer(
            key: ValueKey('renderer_${field.id}'),
            field: field,
            value: formData[field.id],
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

  void _downloadPDF() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF download initiated...')),
      );

    final pdfUrl = '${ApiConfig.djangoBaseUrl}/form-builder/submission/${widget.submissionId}/pdf/view/';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PDF URL: $pdfUrl'),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _exportData() {
    if (_submission == null || !mounted) return;

    try {
      final json = const JsonEncoder.withIndent('  ').convert(_submission!.toJson());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('JSON data ready'),
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              if (!mounted) return;
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                      title: const Text('Submission JSON'),
                      content: SingleChildScrollView(
                        child: SelectableText(json),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
        );
    }
  }
}
