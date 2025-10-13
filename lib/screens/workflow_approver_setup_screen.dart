// lib/screens/workflow_approver_setup_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/workflow_provider.dart';
import '../models/workflow_template.dart';
import '../models/workflow_node.dart';
import '../services/workflow_api_service.dart';
import '../services/workflow_execution_api_service.dart';
import '../widgets/workflow_canvas.dart';
import '../widgets/dialogs/node_edit_dialog.dart';

class WorkflowApproverSetupScreen extends StatefulWidget {
  final int requisitionId;
  final int templateId;

  const WorkflowApproverSetupScreen({
    Key? key,
    required this.requisitionId,
    required this.templateId,
  }) : super(key: key);

  @override
  State<WorkflowApproverSetupScreen> createState() =>
      _WorkflowApproverSetupScreenState();
}

class _WorkflowApproverSetupScreenState
    extends State<WorkflowApproverSetupScreen> {
  final WorkflowApiService _workflowApi = WorkflowApiService();
  final WorkflowExecutionApiService _executionApi = WorkflowExecutionApiService();

  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _loadTemplateForApproverSetup();
  }

  /// Load template structure for approver assignment
  Future<void> _loadTemplateForApproverSetup() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      print('📥 Loading template ${widget.templateId} for approver setup');

      final provider = Provider.of<WorkflowProvider>(context, listen: false);

      // Initialize workflow data (stages, nodes, employees)
      await provider.initialize();

      // Load the specific template
      await provider.loadTemplate(widget.templateId);

      print('✅ Template loaded for approver setup');

      setState(() {
        _loading = false;
      });
    } catch (e) {
      print('❌ Error loading template: $e');
      setState(() {
        _error = 'Failed to load template: $e';
        _loading = false;
      });
    }
  }

  /// ✅ ENHANCED: Comprehensive validation matching React exactly
  List<String> _validateApproverSetup(WorkflowProvider provider) {
    final errors = <String>[];

    print('🔍 Starting comprehensive validation');

    // Check if all approval nodes have approvers assigned
    final approvalNodes = provider.template.nodes
        .where((node) => node.type == 'approval')
        .toList();

    print('📊 Found ${approvalNodes.length} approval nodes to validate');

    final unassignedNodes = approvalNodes.where((node) {
      // ✅ CRITICAL: Use exact same validation logic as React modal
      final hasValidEmployee = node.data.selectedEmployeeId != null &&
          node.data.selectedEmployeeId.toString().isNotEmpty &&
          node.data.selectedEmployeeId.toString() != 'Select Employee...' &&
          node.data.username != null &&
          node.data.username!.isNotEmpty &&
          node.data.username != 'user';

      final hasValidUserId = node.data.userId != null &&
          node.data.userId!.trim().isNotEmpty &&
          node.data.userId!.trim() != 'user' &&
          node.data.userId!.trim() != 'undefined';

      final isValid = hasValidEmployee && hasValidUserId;
      
      if (!isValid) {
        print('❌ Node "${node.data.title ?? node.data.label}" validation failed:');
        print('   - hasValidEmployee: $hasValidEmployee (employeeId: ${node.data.selectedEmployeeId}, username: ${node.data.username})');
        print('   - hasValidUserId: $hasValidUserId (userId: ${node.data.userId})');
      } else {
        print('✅ Node "${node.data.title ?? node.data.label}" validation passed');
      }

      return !isValid;
    }).toList();

    if (unassignedNodes.isNotEmpty) {
      final nodeNames = unassignedNodes
          .map((node) => '"${node.data.title ?? node.data.label}"')
          .join(', ');
      errors.add(
          '${unassignedNodes.length} approval node(s) need complete approver assignment: $nodeNames');
    }

    // Check basic template info
    if (provider.template.name.isEmpty) {
      errors.add('Template Name is required');
    }

    if (provider.selectedStage == null) {
      errors.add('Workflow Stage must be selected');
    }

    // Check if workflow has at least one approval node
    if (approvalNodes.isEmpty) {
      errors.add('Workflow must have at least one approval node');
    }

    print('🔍 Validation complete: ${errors.length} errors found');
    return errors;
  }

  /// ✅ ENHANCED: Save with comprehensive error display
  Future<void> _handleSaveAndCreateWorkflow() async {
    final provider = Provider.of<WorkflowProvider>(context, listen: false);

    print('🔍 Starting validation for Save & Create Workflow');

    final validationErrors = _validateApproverSetup(provider);

    if (validationErrors.isNotEmpty) {
      print('❌ Validation failed: ${validationErrors.length} errors');

      // ✅ CRITICAL: Create detailed error message matching React
      String errorMessage =
          'Cannot save workflow. Please fix the following issues:\n\n';
      for (int i = 0; i < validationErrors.length; i++) {
        errorMessage += '${i + 1}. ${validationErrors[i]}\n';
      }

      errorMessage += '\n📝 Instructions:\n';
      errorMessage += '• Click on each approval node to configure approvers\n';
      errorMessage += '• Select a valid employee from the Username dropdown\n';
      errorMessage += '• Enter a unique User ID for each approver';

      _showDetailedError(errorMessage);
      return;
    }

    print('✅ Validation passed, proceeding with save');

    setState(() {
      _saving = true;
      _error = null;
      _successMessage = null;
    });

    try {
      print('🚀 Saving approver setup and creating workflow records');

      // Step 1: Save template with updated approver assignments
      final saveSuccess = await provider.saveTemplate();

      if (!saveSuccess) {
        throw Exception('Failed to save template with approver assignments');
      }

      print('✅ Template saved with approver assignments');

      // Step 2: Create workflow execution records
      final executionResult = await _executionApi.triggerWorkflowExecution(
        requisitionId: widget.requisitionId,
        workflowTemplateId: widget.templateId,
      );

      if (executionResult['success']) {
        print('✅ Workflow execution created successfully');

        setState(() {
          _successMessage = 'Workflow created and triggered successfully!';
        });

        // Show success message briefly, then navigate back
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          Navigator.pop(context); // Return to requisition view
        }
      } else {
        throw Exception(executionResult['message'] ?? 'Failed to trigger workflow');
      }
    } catch (e) {
      print('❌ Error creating workflow: $e');
      _showDetailedError('Error creating workflow: $e\nPlease try again.');
    } finally {
      setState(() {
        _saving = false;
      });
    }
  }

  /// ✅ NEW: Show detailed error with dialog
  void _showDetailedError(String message) {
    setState(() {
      _error = message;
    });

    // Also show in dialog for better visibility
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red.shade700),
            const SizedBox(width: 8),
            const Text('Validation Error'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    // Also show snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.split('\n').first), // Show first line only
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Details',
          textColor: Colors.white,
          onPressed: () {
            // Dialog already shown
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Consumer<WorkflowProvider>(
        builder: (context, provider, child) {
          if (_loading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text(
                    '🔄 Loading Template for Approver Setup...',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Requisition: ${widget.requisitionId} | Template: ${widget.templateId}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Header
              _buildHeader(provider),

              // Error/Success Messages
              if (_error != null) _buildErrorBanner(),
              if (_successMessage != null) _buildSuccessBanner(),

              // Main content
              Expanded(
                child: Row(
                  children: [
                    // Left sidebar with template info
                    _buildLeftSidebar(provider),

                    // Canvas area (structure read-only, nodes editable)
                    Expanded(
                      child: _buildCanvasArea(provider),
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

  /// Build header
  Widget _buildHeader(WorkflowProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Setup Workflow Approvers',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Configure approvers for requisition ${widget.requisitionId} using template "${provider.template.name}"',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: _saving ? null : _handleSaveAndCreateWorkflow,
            icon: Icon(_saving ? Icons.hourglass_empty : Icons.check),
            label: Text(_saving ? 'Saving...' : 'Save & Create Workflow'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('← Back to Setup'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ ENHANCED: Error banner with better visibility
  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.red.shade100,
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!.split('\n').first, // Show first line in banner
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Error Details'),
                  content: SingleChildScrollView(
                    child: Text(_error!),
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
            child: const Text('View Details'),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => setState(() => _error = null),
          ),
        ],
      ),
    );
  }

  /// Build success banner
  Widget _buildSuccessBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.green.shade100,
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _successMessage!,
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build left sidebar
  Widget _buildLeftSidebar(WorkflowProvider provider) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Template Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Template Name (read-only)
            TextField(
              controller: TextEditingController(text: provider.template.name),
              decoration: const InputDecoration(
                labelText: 'Template Name',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFFF9FAFB),
              ),
              readOnly: true,
              enabled: false,
            ),
            const SizedBox(height: 16),

            // Description (read-only)
            TextField(
              controller: TextEditingController(text: provider.template.description),
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFFF9FAFB),
              ),
              maxLines: 2,
              readOnly: true,
              enabled: false,
            ),
            const SizedBox(height: 16),

            // Workflow Stage (read-only)
            TextField(
              controller: TextEditingController(
                text: provider.selectedStage?.description ?? provider.template.stage,
              ),
              decoration: const InputDecoration(
                labelText: 'Workflow Stage',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFFF9FAFB),
              ),
              readOnly: true,
              enabled: false,
            ),
            const SizedBox(height: 16),

            // Department (read-only)
            TextField(
              controller: TextEditingController(
                text: provider.template.department != null
                    ? 'Department ID: ${provider.template.department}'
                    : 'Global Template',
              ),
              decoration: const InputDecoration(
                labelText: 'Department',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFFF9FAFB),
              ),
              readOnly: true,
              enabled: false,
            ),
            const SizedBox(height: 24),

            // Instructions
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Instructions',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Click on approval nodes to assign approvers\n'
                    '• Select employee from dropdown\n'
                    '• User ID will be auto-filled\n'
                    '• All approval nodes must have valid approvers',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ✅ ENHANCED: Approval nodes summary matching React
            _buildApprovalNodesSummary(provider),
          ],
        ),
      ),
    );
  }

  /// ✅ ENHANCED: Build approval nodes summary with progress indicator
  Widget _buildApprovalNodesSummary(WorkflowProvider provider) {
    final approvalNodes = provider.template.nodes
        .where((node) => node.type == 'approval')
        .toList();

    final assignedNodes = approvalNodes.where((node) {
      final hasValidEmployee = node.data.selectedEmployeeId != null &&
          node.data.selectedEmployeeId.toString().isNotEmpty &&
          node.data.username != null &&
          node.data.username!.isNotEmpty &&
          node.data.username != 'user';

      final hasValidUserId = node.data.userId != null &&
          node.data.userId!.trim().isNotEmpty &&
          node.data.userId!.trim() != 'user';

      return hasValidEmployee && hasValidUserId;
    }).length;

    final isComplete = assignedNodes == approvalNodes.length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isComplete ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isComplete ? Colors.green.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Approver Assignment',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$assignedNodes/${approvalNodes.length}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isComplete ? Colors.green.shade700 : Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: approvalNodes.isEmpty ? 0 : assignedNodes / approvalNodes.length,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              isComplete ? Colors.green : Colors.orange,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isComplete ? Icons.check_circle : Icons.warning,
                size: 16,
                color: isComplete ? Colors.green.shade700 : Colors.orange.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isComplete
                      ? 'All approvers assigned'
                      : '${approvalNodes.length - assignedNodes} node(s) need approvers',
                  style: TextStyle(
                    fontSize: 12,
                    color: isComplete ? Colors.green.shade700 : Colors.orange.shade700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ✅ FIXED: Build canvas area using existing WorkflowCanvas widget
  Widget _buildCanvasArea(WorkflowProvider provider) {
    return Container(
      color: Colors.grey[100],
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: WorkflowCanvas(
            nodes: provider.template.nodes,
            edges: provider.template.edges,
            // ✅ FIXED: WorkflowCanvas handles drag internally
            onNodeDrag: (nodeId, position) {
              // Allow node dragging for repositioning
              provider.updateNodePosition(nodeId, position);
            },
            // ✅ FIXED: WorkflowCanvas handles click/drag distinction internally
            onNodeTap: (nodeId) {
              final node = provider.template.nodes.firstWhere((n) => n.id == nodeId);
              // Only allow editing approval nodes
              if (node.type == 'approval') {
                print('✅ Opening modal for approval node: $nodeId');
                provider.selectNode(nodeId);
                _showNodeEditDialog(provider, nodeId);
              }
            },
            connectionMode: false, // Disable connection mode in approver setup
            connectionSource: null,
            onStartConnection: (nodeId) {
              // Disable connection creation in approver setup
            },
            onCompleteConnection: (nodeId) {
              // Disable connection creation in approver setup
            },
            onCancelConnection: () {
              // Disable connection creation in approver setup
            },
            onDeleteEdge: (edgeId) {
              // Disable edge deletion in approver setup
            },
            readonly: false, // Allow node editing but not structure changes
          ),
        ),
      ),
    );
  }

  /// ✅ ENHANCED: Show node edit dialog with validation
  void _showNodeEditDialog(WorkflowProvider provider, String nodeId) {
    final node = provider.template.nodes.firstWhere((n) => n.id == nodeId);

    // Only show edit dialog for approval nodes
    if (node.type != 'approval') return;

    showDialog(
      context: context,
      builder: (context) => NodeEditDialog(
        node: node,
        nodeId: nodeId,
        availableEmployees: provider.availableEmployees,
        loadingEmployees: provider.loadingEmployees,
        onUpdateNode: (nodeId, newData) {
          provider.updateNodeData(nodeId, newData);
        },
        onDeleteNode: (nodeId) {
          // Disable node deletion in approver setup
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot delete nodes in approver setup mode'),
              backgroundColor: Colors.orange,
            ),
          );
        },
      ),
    );
  }
}
