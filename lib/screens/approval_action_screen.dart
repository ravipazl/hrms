// lib/screens/approval_action_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html;
import '../models/approval/workflow_step_detail.dart';
import '../services/workflow_approval_api_service.dart';

class ApprovalActionScreen extends StatefulWidget {
  final int stepId;
  final String suggestedAction;

  const ApprovalActionScreen({
    Key? key,
    required this.stepId,
    this.suggestedAction = 'approved',
  }) : super(key: key);

  @override
  State<ApprovalActionScreen> createState() => _ApprovalActionScreenState();
}

class _ApprovalActionScreenState extends State<ApprovalActionScreen> {
  final WorkflowApprovalApiService _apiService = WorkflowApprovalApiService();
  final TextEditingController _commentsController = TextEditingController();

  WorkflowStepDetail? _workflowStep;
  String _selectedAction = '';
  List<PositionApproval> _positionApprovals = [];
  List<ActionOutcome> _availableOutcomes = [];

  bool _loading = true;
  bool _submitting = false;
  String? _error;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    // Don't set default action - user must select one
    _loadWorkflowStep();
    
    // Add listener to comments controller to update button state
    _commentsController.addListener(() {
      setState(() {
        // Trigger rebuild when comments change
      });
    });
  }

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkflowStep() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      print('🔍 Loading workflow step: ${widget.stepId}');

      final workflowStep = await _apiService.getWorkflowStep(widget.stepId);

      setState(() {
        _workflowStep = workflowStep;
        _loading = false;
      });

      // Load available outcomes
      await _loadAvailableOutcomes();

      // Initialize position approvals
      _initializePositionApprovals();
    } catch (e) {
      setState(() {
        _error = 'Failed to load workflow step: $e';
        _loading = false;
      });
    }
  }

  Future<void> _loadAvailableOutcomes() async {
    if (_workflowStep == null) return;

    try {
      final outcomes = await _apiService.getAvailableOutcomes(
        _workflowStep!.selectedWorkflowId,
        _workflowStep!.workflowNode,
      );

      setState(() {
        _availableOutcomes = outcomes;
      });

      // Don't set default action - user must select one explicitly
    } catch (e) {
      print('❌ Error loading outcomes: $e');
    }
  }

  void _initializePositionApprovals() {
    if (_workflowStep?.positions == null) return;

    final approvals =
        _workflowStep!.positions.map((pos) {
          final maxAllowed =
              pos.approvedHead > 0 ? pos.approvedHead : pos.requisitionQuantity;

          return PositionApproval(
            positionId: pos.id,
            requisitionQuantity: pos.requisitionQuantity,
            approvedHead: pos.approvedHead,
            pending: pos.requisitionQuantity - pos.approvedHead,
            approvedCount: 0,
            maxAllowed: maxAllowed,
            typeRequisitionName: pos.typeRequisitionName ?? 'Position',
          );
        }).toList();

    setState(() {
      _positionApprovals = approvals;
    });
  }

  void _handleApprovalCountChange(int positionId, String value) {
    final numValue = int.tryParse(value) ?? 0;
    setState(() {
      _positionApprovals =
          _positionApprovals.map((pos) {
            if (pos.positionId == positionId) {
              return PositionApproval(
                positionId: pos.positionId,
                requisitionQuantity: pos.requisitionQuantity,
                approvedHead: pos.approvedHead,
                pending: pos.pending,
                approvedCount: numValue,
                maxAllowed: pos.maxAllowed,
                typeRequisitionName: pos.typeRequisitionName,
              );
            }
            return pos;
          }).toList();
    });
  }

  Future<void> _handleSubmit() async {
    // Validate action is selected
    if (_selectedAction.isEmpty) {
      setState(() {
        _error = 'Please select an action (Approved, Hold, or Rejected)';
      });
      return;
    }

    // Validate comments
    if (_commentsController.text.trim().isEmpty) {
      setState(() {
        _error = 'Please add comments for your decision';
      });
      return;
    }

    // Validate partial approvals
    if (_selectedAction == 'approved' && _positionApprovals.isNotEmpty) {
      for (var pos in _positionApprovals) {
        if (pos.hasError) {
          setState(() {
            _error =
                'Cannot approved ${pos.approvedCount} for ${pos.typeRequisitionName}. Maximum allowed: ${pos.maxAllowed}';
          });
          return;
        }
      }
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      // Prepare approved positions data
      List<Map<String, int>>? approvedPositionsData;
      if (_selectedAction == 'approved' && _positionApprovals.isNotEmpty) {
        approvedPositionsData =
            _positionApprovals
                .where((pos) => pos.approvedCount > 0)
                .map(
                  (pos) => {
                    'position_id': pos.positionId,
                    'approved_count': pos.approvedCount,
                  },
                )
                .toList();
      }

      final result = await _apiService.updateStepStatus(
        stepId: widget.stepId,
        outcome: _selectedAction,
        comments: _commentsController.text.trim(),
        approvedPositions: approvedPositionsData,
      );

      if (result['success'] == true) {
        final totalApproved =
            approvedPositionsData?.fold(
              0,
              (sum, p) => sum + p['approved_count']!,
            ) ??
            0;
        final activatedCount = result['data']?['activated_count'] ?? 0;

        final approvalSummary =
            totalApproved > 0 ? ' Approved $totalApproved positions.' : '';

        setState(() {
          _successMessage =
              'Step $_selectedAction successfully!$approvalSummary $activatedCount next step(s) activated.';
        });

        // Redirect after 2 seconds
        await Future.delayed(const Duration(seconds: 2));
        _handleCancel();
      } else {
        throw Exception(result['message'] ?? 'Unknown error occurred');
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
      });
    } finally {
      setState(() {
        _submitting = false;
      });
    }
  }

  void _handleCancel() {
    html.window.location.href =
        'http://127.0.0.1:8000/workflow/pending-approvals/';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading approval details...'),
            ],
          ),
        ),
      );
    }

    if (_error != null && _workflowStep == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(32),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'Error Loading Approval',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _handleCancel,
                      child: const Text('Back to List'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_successMessage != null) _buildSuccessMessage(),
                if (_error != null && _workflowStep != null)
                  _buildErrorMessage(),
                _buildRequisitionDetailsCard(),
                const SizedBox(height: 16),
                if (_positionApprovals.isNotEmpty) ...[
                  _buildPositionApprovalCard(),
                  const SizedBox(height: 16),
                ],
                _buildApprovalActionCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final selectedOutcome = _availableOutcomes.firstWhere(
      (o) => o.value == _selectedAction,
      orElse:
          () => ActionOutcome(
            value: _selectedAction,
            label: _selectedAction,
            color: Colors.blue,
            icon: '❓',
          ),
    );

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: _handleCancel,
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Workflow Approval',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          // Text(
          //   '${_workflowStep?.workflowNodeDescription ?? ''} - ${_workflowStep?.templateName ?? ''}',
          //   style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          // ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: TextButton(
            onPressed: _submitting ? null : _handleCancel,
            child: const Text('Back to List'),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessMessage() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 24),
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

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildRequisitionDetailsCard() {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔹 Header with gradient
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[500]!, Colors.blue[600]!],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
          child: Text(
            'Requisition Details - ${_workflowStep?.requisitionId ?? ''}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),

        // 🔹 Body content
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ✅ Combine these three fields in one horizontal line
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildDetailRow(
                      'Position Requested',
                      _workflowStep?.jobPosition ?? 'N/A',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDetailRow(
                      'Department',
                      _workflowStep?.departmentName ?? 'N/A',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDetailRow(
                      'Job Description',
                      _workflowStep?.jobDescription ?? 'N/A',
                    ),
                  ),
                ],
              ),

              const Divider(height: 32),

              // ✅ Specifications section
              _buildSpecificationsRow(),

              // ✅ Position Details section
              if (_workflowStep?.positions != null &&
                  _workflowStep!.positions.isNotEmpty) ...[
                const Divider(height: 32),
                ..._workflowStep!.positions.asMap().entries.map((entry) {
                  return _buildPositionDetailCard(entry.value, entry.key + 1);
                }).toList(),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}


  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecificationsRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          color: Colors.blue[50],
          child: const Text(
            'Person Specification & Requirements',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildSpecItem(
                'Preferred Gender',
                _workflowStep?.preferredGenderName ?? 'Any',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSpecItem(
                'Age Group',
                _workflowStep?.preferredAgeGroup ?? 'Not specified',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSpecItem(
                'Qualification',
                _workflowStep?.qualification ?? 'N/A',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSpecItem(
                'Experience',
                _workflowStep?.experience ?? 'N/A',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpecItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildPositionDetailCard(PositionDetail position, int index) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ Section Title (kept)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          color: Colors.blue[50],
          child: const Center(
            child: Text(
              ' Position Details',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
                fontSize: 16,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        Text(
          'Position #$index',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),

        const SizedBox(height: 12),

        // ✅ Position basic info
        Row(
          children: [
            Expanded(
              child: _buildPositionDetail(
                'Quantity',
                position.requisitionQuantity.toString(),
              ),
            ),
            Expanded(
              child: _buildPositionDetail(
                'Type',
                position.typeRequisitionName ?? 'N/A',
              ),
            ),
            Expanded(
              child: _buildPositionDetail(
                'Employment',
                position.employmentTypeName ?? 'N/A',
              ),
            ),
          ],
        ),

        // ✅ Replacement details
        if (position.employeeName != null &&
            position.employeeName!.trim().isNotEmpty) ...[
          const Divider(height: 24),
          Text(
            '🔄 Replacement Employee Details',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          _buildPositionDetail('Employee Name', position.employeeName!),
          if (position.employeeNo != null)
            _buildPositionDetail('Employee No', position.employeeNo!),
          if (position.dateOfResignation != null)
            _buildPositionDetail(
              'Resignation Date',
              _formatDate(position.dateOfResignation!),
            ),
        ],

        // ✅ Justification section
        if (position.justificationText != null &&
            position.justificationText!.trim().isNotEmpty) ...[
          const Divider(height: 24),
          Text(
            'Justification',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            position.justificationText!,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ],
    ),
  );
}

  Widget _buildPositionDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionApprovalCard() {
    return Card(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green[500]!, Colors.green[600]!],
              ),
            ),
            child: const Text(
              ' Position Approval Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children:
                  _positionApprovals.asMap().entries.map((entry) {
                    return _buildPositionApprovalInput(
                      entry.value,
                      entry.key + 1,
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionApprovalInput(PositionApproval pos, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: pos.hasError ? Colors.red[300]! : Colors.grey[300]!,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Position $index: ${pos.typeRequisitionName}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Requested: ${pos.requisitionQuantity}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Approval:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '0',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        errorText:
                            pos.hasError ? 'Max: ${pos.maxAllowed}' : null,
                      ),
                      onChanged:
                          (value) =>
                              _handleApprovalCountChange(pos.positionId, value),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalActionCard() {
    final selectedOutcome = _availableOutcomes.firstWhere(
      (o) => o.value == _selectedAction,
      orElse:
          () => ActionOutcome(
            value: _selectedAction,
            label: _selectedAction,
            color: Colors.blue,
            icon: '❓',
          ),
    );

    return Card(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: selectedOutcome.color,
            child: Row(
              children: [
                // Text(
                //   selectedOutcome.icon,
                //   style: const TextStyle(fontSize: 24, color: Colors.white),
                // ),
                const SizedBox(width: 12),
                Text(
                  '${selectedOutcome.label} Workflow Step',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _buildWorkflowInfo()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildAssignmentInfo()),
                  ],
                ),
                const Divider(height: 32),
                _buildActionSelector(),
                const SizedBox(height: 24),
                _buildCommentsField(),
                const SizedBox(height: 24),
                _buildActionButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Workflow Details',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildInfoRow('Step', _workflowStep?.workflowNodeDescription ?? ''),
        _buildInfoRow('Template', _workflowStep?.templateName ?? ''),
        _buildInfoRow('Requisition', _workflowStep?.requisitionId ?? ''),
      ],
    );
  }

  Widget _buildAssignmentInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Assignment Details',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildInfoRow('Assigned To', _workflowStep?.assignedTo ?? ''),
        _buildInfoRow(
          'Started',
          _workflowStep?.startDate != null
              ? DateFormat(
                'MMM dd, yyyy HH:mm',
              ).format(_workflowStep!.startDate!)
              : 'N/A',
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Action',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (_availableOutcomes.isEmpty)
          const Center(child: CircularProgressIndicator())
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:
                _availableOutcomes.map((outcome) {
                  final isSelected = _selectedAction == outcome.value;
                  final width =
                      (MediaQuery.of(context).size.width - 80) /
                      _availableOutcomes.length;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: InkWell(
                        onTap:
                            () =>
                                setState(() => _selectedAction = outcome.value),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? outcome.color.withOpacity(0.15)
                                    : Colors.white,
                            border: Border.all(
                              color:
                                  isSelected
                                      ? outcome.color
                                      : Colors.grey[300]!,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Text(
                              //   outcome.icon,
                              //   style: const TextStyle(fontSize: 30),
                              // ),
                              const SizedBox(height: 8),
                              Text(
                                outcome.label,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isSelected
                                          ? outcome.color
                                          : Colors.grey[700],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
      ],
    );
  }

  Widget _buildCommentsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Comments',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 4),
            Text('*', style: TextStyle(color: Colors.red, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _commentsController,
          maxLines: 5,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText:
                'Please provide your reason for $_selectedAction this workflow step...',
          ),
          enabled: !_submitting,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final selectedOutcome = _availableOutcomes.firstWhere(
      (o) => o.value == _selectedAction,
      orElse:
          () => ActionOutcome(
            value: _selectedAction,
            label: _selectedAction,
            color: Colors.grey,
            icon: '❓',
          ),
    );

    // Button is enabled only if:
    // 1. Not submitting
    // 2. Action is selected
    // 3. Comments are not empty
    final isButtonEnabled = !_submitting && 
                           _selectedAction.isNotEmpty && 
                           _commentsController.text.trim().isNotEmpty;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _submitting ? null : _handleCancel,
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: isButtonEnabled ? _handleSubmit : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: selectedOutcome.color,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            disabledForegroundColor: Colors.grey.shade600,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          child:
              _submitting
                  ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('Processing...'),
                    ],
                  )
                  : Text(
                      _selectedAction.isEmpty 
                          ? 'Select Action First'
                          : '${selectedOutcome.label} Step',
                    ),
        ),
      ],
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }
}
