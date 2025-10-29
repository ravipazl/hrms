// lib/screens/requisition_view_screen.dart
// Updated with equal spacing for card fields and person specification fields

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html;
import '../models/requisition.dart';
import '../models/workflow_execution/workflow_execution.dart';
import '../models/workflow_template.dart';
import '../services/requisition_api_service.dart';
import '../services/workflow_execution_api_service.dart';
import 'workflow_approver_setup_screen.dart';
import '../services/api_config.dart';
class RequisitionViewScreen extends StatefulWidget {
  final int requisitionId;

  const RequisitionViewScreen({
    Key? key,
    required this.requisitionId,
  }) : super(key: key);

  @override
  State<RequisitionViewScreen> createState() => _RequisitionViewScreenState();
}

class _RequisitionViewScreenState extends State<RequisitionViewScreen> {
  final RequisitionApiService _requisitionApi = RequisitionApiService();
  final WorkflowExecutionApiService _workflowApi = WorkflowExecutionApiService();

  Requisition? _requisition;
  WorkflowExecution? _workflowExecution;
  List<WorkflowTemplate> _availableTemplates = [];

  bool _loading = true;
  bool _loadingTemplates = false;
  bool _isUpdating = false;
  String? _error;
  String? _successMessage;

  String _selectedStatus = "";
  int? _selectedTemplateId;

  final List<String> _validStatuses = ['Pending', 'Approved', 'Rejected', 'Hold'];

  @override
  void initState() {
    super.initState();
    _loadRequisition();
    _loadWorkflowExecutionStatus();
  }

  Future<void> _loadRequisition() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      print('🔍 Loading requisition: ${widget.requisitionId}');
      
      final requisition = await _requisitionApi.getRequisition(widget.requisitionId);
      
      setState(() {
        _requisition = requisition;
        if (requisition.status != null && requisition.status!.isNotEmpty) {
          _selectedStatus = requisition.status!;
        } else {
          _selectedStatus = "Pending";
        }
        _loading = false;
      });

      if (_requisition?.department != null) {
        print('🔄 Department loaded, fetching workflow templates');
        _loadWorkflowTemplates();
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load requisition: $e';
        _loading = false;
      });
    }
  }

  Future<void> _loadWorkflowExecutionStatus() async {
    try {
      final result = await _workflowApi.getWorkflowExecutionStatus(widget.requisitionId);
      
      if (result['status'] == 'success') {
        setState(() {
          _workflowExecution = result['data'] as WorkflowExecution;
        });
      } else {
        setState(() {
          _workflowExecution = WorkflowExecution(workflowConfigured: false);
        });
      }
      
      if (mounted) setState(() {});
    } catch (e) {
      setState(() {
        _workflowExecution = WorkflowExecution(workflowConfigured: false);
      });
    }
  }

  Future<void> _loadWorkflowTemplates() async {
    setState(() => _loadingTemplates = true);

    try {
      int? departmentId;
      if (_requisition?.department != null) {
        if (_requisition!.department is int) {
          departmentId = _requisition!.department as int;
        } else if (_requisition!.department is String) {
          departmentId = int.tryParse(_requisition!.department as String);
        }
      }
      
      final templates = await _workflowApi.getAvailableTemplates(departmentId: departmentId);
      setState(() {
        _availableTemplates = templates;
        _loadingTemplates = false;
      });
    } catch (e) {
      setState(() {
        _availableTemplates = [];
        _loadingTemplates = false;
      });
    }
  }

  bool _canEditRequisitionStatus() {
    return _workflowExecution != null && !_workflowExecution!.workflowConfigured;
  }

  bool _canSetupWorkflow() {
    final isApproved = _requisition?.status == 'Approved';
    final workflowNotConfigured = _workflowExecution != null && !_workflowExecution!.workflowConfigured;
    return isApproved && workflowNotConfigured;
  }

  bool _hasWorkflow() {
    return _workflowExecution?.workflowConfigured == true &&
           _workflowExecution?.workflowSteps != null &&
           _workflowExecution!.workflowSteps.isNotEmpty;
  }

  Future<void> _handleUpdateStatus() async {
    if (_selectedStatus.isEmpty || _selectedStatus == "-- Select --") {
      _showError('Please select a status');
      return;
    }

    setState(() {
      _isUpdating = true;
      _error = null;
      _successMessage = null;
    });

    try {
      final result = await _workflowApi.updateRequisitionStatus(widget.requisitionId, _selectedStatus);

      if (result['success']) {
        setState(() {
          if (_requisition != null) {
            _requisition = _requisition!.copyWith(status: _selectedStatus);
          }
          _successMessage = 'Status updated to $_selectedStatus successfully!';
        });

        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _successMessage = null);
        });
      } else {
        _showError(result['message'] ?? 'Failed to update status');
      }
    } catch (e) {
      _showError('Error updating status: $e');
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  void _handleSelectWorkflow() {
    if (_selectedTemplateId == null) {
      _showError('Please select a workflow template first');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkflowApproverSetupScreen(
          requisitionId: widget.requisitionId,
          templateId: _selectedTemplateId!,
        ),
      ),
    ).then((_) {
      _loadRequisition();
      _loadWorkflowExecutionStatus();
    });
  }

  void _handleNavigateToCreateTemplate() {
    html.window.location.href = '${ApiConfig.djangoBaseUrl}/workflow/templates/create/';
  }

  void _showError(String message) {
    setState(() => _error = message);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return Colors.green.shade700;
      case 'rejected': return Colors.red.shade700;
      case 'hold': return Colors.orange.shade700;
      default: return Colors.blue.shade900;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_requisition == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No Data Found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Requisition data could not be loaded.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => html.window.location.href = '${ApiConfig.djangoBaseUrl}/requisition/',
                child: const Text('Back to List'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSingleRowHeader(),
              const SizedBox(height: 16),
              if (_successMessage != null) _buildSuccessMessage(),
              if (_error != null) _buildErrorMessage(),
              const SizedBox(height: 16),
              _buildMainContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSingleRowHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => html.window.location.href = '${ApiConfig.djangoBaseUrl}/requisition/',
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Requisition Approval & Review',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Text('Current Status:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 6),
                    _buildStatusBadge(_requisition?.status ?? 'Pending'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(flex: 1, child: _buildRequisitionVerificationSection()),
          const SizedBox(width: 16),
          Expanded(flex: 1, child: _buildWorkflowSetupSection()),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor, textColor;
    switch (status.toLowerCase()) {
      case 'approved':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        break;
      case 'rejected':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        break;
      case 'hold':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: textColor),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildRequisitionVerificationSection() {
    String? dropdownValue;
    if (_validStatuses.contains(_selectedStatus)) {
      dropdownValue = _selectedStatus;
    } else {
      dropdownValue = 'Pending';
      _selectedStatus = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Requisition Verification ${_workflowExecution?.workflowConfigured == true ? '' : ''}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          if (_canEditRequisitionStatus())
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: dropdownValue,
                        isExpanded: true,
                        isDense: true,
                        style: const TextStyle(fontSize: 11, color: Colors.black87),
                        items: _validStatuses
                            .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                            .toList(),
                        onChanged: _isUpdating ? null : (value) {
                          if (value != null) setState(() => _selectedStatus = value);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: _isUpdating || dropdownValue == null ? null : _handleUpdateStatus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade500,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: Text(_isUpdating ? 'Updating...' : 'Update', style: const TextStyle(fontSize: 11)),
                  ),
                ),
              ],
            )
          else
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue.shade200),
              ),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getStatusColor(_requisition?.status ?? 'Pending'),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _requisition?.status ?? 'Pending',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _getStatusColor(_requisition?.status ?? 'Pending'),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWorkflowSetupSection() {
    final canSetup = _canSetupWorkflow();
    final workflowConfigured = _workflowExecution?.workflowConfigured == true;

    int? templateDropdownValue;
    if (_selectedTemplateId != null && _availableTemplates.any((t) => t.id == _selectedTemplateId)) {
      templateDropdownValue = _selectedTemplateId;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            canSetup ? ' Workflow Setup Required' : 'Workflow Setup',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: canSetup ? Colors.orange.shade800 : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          if (workflowConfigured)
            _buildWorkflowProgress()
          else
            _buildTemplateSelection(canSetup, templateDropdownValue),
        ],
      ),
    );
  }

  Widget _buildWorkflowProgress() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Progress:', style: TextStyle(fontSize: 10, color: Colors.grey)),
            Text(
              '${_workflowExecution!.statistics?.completedSteps ?? 0}/${_workflowExecution!.statistics?.totalSteps ?? 0}',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.green),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 4,
          child: LinearProgressIndicator(
            value: (_workflowExecution!.statistics?.completionPercentage ?? 0) / 100,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateSelection(bool canSetup, int? templateDropdownValue) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: canSetup ? Colors.white : Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: templateDropdownValue,
                    isExpanded: true,
                    isDense: true,
                    style: TextStyle(fontSize: 11, color: canSetup ? Colors.black87 : Colors.grey),
                    hint: Text(
                      _loadingTemplates ? 'Loading...' : canSetup ? '-- Select Template --' : 'Approve to enable',
                      style: const TextStyle(fontSize: 11),
                    ),
                    items: canSetup
                        ? _availableTemplates
                            .map((template) => DropdownMenuItem(
                                  value: template.id,
                                  child: Text(template.name, overflow: TextOverflow.ellipsis),
                                ))
                            .toList()
                        : null,
                    onChanged: canSetup && !_loadingTemplates ? (value) => setState(() => _selectedTemplateId = value) : null,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(
              height: 36,
              width: 48,
              child: ElevatedButton(
                onPressed: canSetup && templateDropdownValue != null && !_loadingTemplates ? _handleSelectWorkflow : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade500,
                  padding: const EdgeInsets.all(0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: const Text('Use', style: TextStyle(fontSize: 11)),
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(
              height: 36,
              width: 60,
              child: ElevatedButton(
                onPressed: canSetup ? _handleNavigateToCreateTemplate : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade500,
                  padding: const EdgeInsets.all(0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: const Text('Create', style: TextStyle(fontSize: 11)),
              ),
            ),
          ],
        ),
        
      ],
    );
  }

  Widget _buildSuccessMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _successMessage!,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.green.shade800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Error', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red.shade800)),
                const SizedBox(height: 4),
                Text(_error!, style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // MAIN CONTENT - WITH EQUAL SPACING
  // ============================================

  Widget _buildMainContent() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildLogoAndHeaderRow(),
          _buildMainTitleRow(),
          _buildDepartmentAndToRow(),
          _buildPositionRequestedRow(),
          _buildJobDescriptionRow(),
          _buildRequisitionCardsSectionHeader(),
          _buildRequisitionCards(),
          _buildPersonSpecificationHeader(),
          _buildPersonSpecificationSingleRow(),
          _buildSkillsHeader(),
          _buildEssentialSkillsRow(),
          _buildDesirableSkillsRow(),
          _buildJustificationRow(),
          if (_hasWorkflow()) ...[
            _buildWorkflowStatusHeader(),
            _buildWorkflowSummaryRow(),
            _buildWorkflowTimeline(),
          ] else
            _buildNoWorkflowMessage(),
        ],
      ),
    );
  }

  Widget _buildLogoAndHeaderRow() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo from assets
          Image.asset(
            'assets/images/logo.png',
            width: 50,
            height: 50,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to icon if image fails to load
              return Icon(Icons.business, size: 32, color: Colors.blue.shade700);
            },
          ),
          Expanded(
            child: Column(
              children: [
                Text('SRI RAMACHANDRA MEDICAL CENTER',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                    textAlign: TextAlign.center),
                const SizedBox(height: 2),
                Text('PORUR, CHENNAI-600116',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
          Text(_requisition?.requisitionId ?? '',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _buildMainTitleRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
      child: Center(
        child: Text('TALENT REQUISITION FORM - NEW HIRE / REPLACEMENT',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
            textAlign: TextAlign.center),
      ),
    );
  }

  Widget _buildDepartmentAndToRow() {
    final departmentName = _requisition?.departmentName ?? _requisition?.department?.toString() ?? 'Not specified';
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.grey.shade300))),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FROM : Department / HOD (Name)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(departmentName,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue.shade600)),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Text('TO  ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                  Expanded(
                    child: Text('Human Resources Development Dept.',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade900)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionRequestedRow() {
    final jobPosition = _requisition?.jobPosition ?? 'Not specified';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Position Requested: ',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
          Expanded(
            child: Text(jobPosition,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue.shade600)),
          ),
        ],
      ),
    );
  }

  Widget _buildJobDescriptionRow() {
    final hasTextDescription = _requisition?.jobDescription != null && _requisition!.jobDescription!.trim().isNotEmpty;
    
    // ENHANCED: Check for multiple documents (jobDocuments array)
    final hasMultipleDocuments = _requisition?.jobDocuments != null && _requisition!.jobDocuments!.isNotEmpty;
    
    // Fallback: Check for single document (legacy support)
    final hasSingleDocument = !hasMultipleDocuments && 
                              (_requisition?.jobDocumentUrl != null && _requisition!.jobDocumentUrl!.isNotEmpty);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Job Description: ',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
              Expanded(
                child: Text(
                  hasTextDescription
                      ? _requisition!.jobDescription!
                      : (hasMultipleDocuments || hasSingleDocument ? '' : 'No job description provided'),
                  style: TextStyle(
                    fontSize: 12,
                    color: hasTextDescription ? Colors.blue.shade600 : Colors.grey.shade500,
                    fontStyle: hasTextDescription ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
          
          // ENHANCED: Display multiple documents from jobDocuments array
          if (hasMultipleDocuments) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.attach_file, size: 14, color: Colors.blue.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Attached Documents (${_requisition!.jobDocuments!.length})',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._requisition!.jobDocuments!.asMap().entries.map((entry) {
                    final index = entry.key;
                    final doc = entry.value;
                    final fileName = doc['name']?.toString() ?? 'Document ${index + 1}';
                    final fileUrl = doc['url']?.toString() ?? '';
                    final fileSize = doc['size'];
                    final fileType = doc['type']?.toString() ?? '';
                    
                    // Format file size
                    String formattedSize = 'Unknown size';
                    if (fileSize != null && fileSize is int) {
                      if (fileSize < 1024) {
                        formattedSize = '$fileSize B';
                      } else if (fileSize < 1024 * 1024) {
                        formattedSize = '${(fileSize / 1024).toStringAsFixed(1)} KB';
                      } else {
                        formattedSize = '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
                      }
                    }
                    
                    // Determine icon based on file type
                    IconData fileIcon = Icons.insert_drive_file;
                    Color iconColor = Colors.grey.shade600;
                    if (fileType.contains('pdf')) {
                      fileIcon = Icons.picture_as_pdf;
                      iconColor = Colors.red.shade600;
                    } else if (fileType.contains('image') || 
                               fileName.toLowerCase().endsWith('.jpg') || 
                               fileName.toLowerCase().endsWith('.jpeg') || 
                               fileName.toLowerCase().endsWith('.png')) {
                      fileIcon = Icons.image;
                      iconColor = Colors.blue.shade600;
                    } else if (fileName.toLowerCase().endsWith('.doc') || 
                               fileName.toLowerCase().endsWith('.docx')) {
                      fileIcon = Icons.description;
                      iconColor = Colors.blue.shade800;
                    }
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      child: InkWell(
                        onTap: () {
                          String url = fileUrl;
                          if (!url.startsWith('http')) {
                            url = '${ApiConfig.djangoBaseUrl}$url';
                          }
                          print('📂 Opening document: $url');
                          html.window.open(url, '_blank');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(fileIcon, size: 16, color: iconColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fileName,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.blue.shade700,
                                        decoration: TextDecoration.underline,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      formattedSize,
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.open_in_new,
                                size: 14,
                                color: Colors.blue.shade600,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ]
          // Fallback: Display single document (legacy support)
          else if (hasSingleDocument) ...[
            const SizedBox(height: 4),
            InkWell(
              onTap: () {
                String url = _requisition!.jobDocumentUrl!;
                if (!url.startsWith('http')) url = '${ApiConfig.djangoBaseUrl}$url';
                html.window.open(url, '_blank');
              },
              child: Text(
                '📎 ${_requisition!.jobDocumentUrl!.split('/').last}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.blue.shade600,
                  decoration: TextDecoration.underline,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRequisitionCardsSectionHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Center(
        child: Text('Requisition Details Cards',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
      ),
    );
  }

  Widget _buildRequisitionCards() {
    final positions = _requisition?.positions ?? [];
    if (positions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text('No position details available',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
        ),
      );
    }
    return Column(
      children: positions.asMap().entries.map((entry) {
        return _buildSingleRequisitionCard(entry.value, entry.key + 1);
      }).toList(),
    );
  }

  // SINGLE LINE - Requisition Card Fields (only horizontal borders)
  Widget _buildSingleRequisitionCard(RequisitionPosition position, int cardNumber) {
    final isReplacement = position.typeRequisition == '2';
    
    // Get display values
    final typeDisplay = position.typeRequisitionDisplay ?? (isReplacement ? 'Replacement' : 'New Hire');
    final reasonDisplay = isReplacement 
        ? (position.requirementsRequisitionReplacementDisplay ?? 'Not specified')
        : (position.requirementsRequisitionNewhireDisplay ?? 'Not specified');
    final employmentTypeDisplay = position.employmentTypeDisplay ?? 'Not specified';
    
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: Colors.grey.shade50,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Requisition Details Card #$cardNumber',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ),
          // SINGLE HORIZONTAL LINE - All fields in one row with even spacing
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: _buildInlineField('Type:', typeDisplay)),
                Flexible(child: _buildInlineField('Reason for Requisition:', reasonDisplay)),
                Flexible(child: _buildInlineField('Head Count:', '${position.requisitionQuantity}')),
                Flexible(child: _buildInlineField('Vacancy to be filled on:', position.vacancyToBeFilled ?? 'Not specified')),
                Flexible(child: _buildInlineField('Employment Type:', employmentTypeDisplay)),
                Flexible(child: _buildInlineField('Justification:', position.justificationText ?? 'Not provided')),
              ],
            ),
          ),
          if (isReplacement && position.employeeName != null && position.employeeName!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: Colors.grey.shade50,
              child: const Text('Employee Information', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                  bottom: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: _buildInlineField('Employee Name:', position.employeeName ?? '')),
                  Flexible(child: _buildInlineField('Employee No:', position.employeeNo ?? 'Not specified')),
                  Flexible(child: _buildInlineField('Date of Resignation:', position.dateOfResignation ?? 'Not specified')),
                  Flexible(child: _buildInlineField('Resignation Reason:', position.resignationReason ?? 'Not specified')),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Helper widget for inline field (label and value side-by-side)
  Widget _buildInlineField(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
          overflow: TextOverflow.visible,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 11,
              color: Colors.blue.shade600,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonSpecificationHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Center(
        child: Text('Person Specification & Justification',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
      ),
    );
  }

  // SINGLE LINE - Person Specification Fields (only horizontal borders)
  Widget _buildPersonSpecificationSingleRow() {
    // Use display value for gender if available, otherwise fallback to ID or "Any"
    final genderDisplay = _requisition?.preferredGenderDisplay ?? 
                          (_requisition?.preferredGender != null ? _requisition!.preferredGender! : 'Any');
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: _buildInlineField('Preferred Gender:', genderDisplay)),
          Flexible(child: _buildInlineField('Preferred Age Group:', _requisition?.preferredAgeGroup ?? 'Not specified')),
          Flexible(child: _buildInlineField('Qualification:', _requisition?.qualification ?? 'Not specified')),
          Flexible(child: _buildInlineField('Experience:', _requisition?.experience ?? 'Not specified')),
        ],
      ),
    );
  }

  Widget _buildSkillsHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Center(
        child: Text('Skills',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
      ),
    );
  }

  Widget _buildEssentialSkillsRow() {
    final essentialSkills = _requisition?.skills
            ?.where((skill) => skill.skillType == 'essential')
            .map((skill) => skill.skill)
            .join(', ') ??
        '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Essential Skills: ',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
          Expanded(
            child: Text(
              essentialSkills.isNotEmpty ? essentialSkills : 'Not specified',
              style: TextStyle(
                fontSize: 11,
                color: essentialSkills.isNotEmpty ? Colors.blue.shade600 : Colors.grey.shade500,
                fontStyle: essentialSkills.isNotEmpty ? FontStyle.normal : FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesirableSkillsRow() {
    final desirableSkills = _requisition?.skills
            ?.where((skill) => skill.skillType == 'desired' || skill.skillType == 'desirable')
            .map((skill) => skill.skill)
            .join(', ') ??
        '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Desirable Skills: ',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
          Expanded(
            child: Text(
              desirableSkills.isNotEmpty ? desirableSkills : 'Not specified',
              style: TextStyle(
                fontSize: 11,
                color: desirableSkills.isNotEmpty ? Colors.blue.shade600 : Colors.grey.shade500,
                fontStyle: desirableSkills.isNotEmpty ? FontStyle.normal : FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJustificationRow() {
    final justification = _requisition?.justificationText ?? '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Justification: ',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
          Expanded(
            child: Text(
              justification.isNotEmpty ? justification : 'Not provided',
              style: TextStyle(
                fontSize: 11,
                color: justification.isNotEmpty ? Colors.blue.shade600 : Colors.grey.shade500,
                fontStyle: justification.isNotEmpty ? FontStyle.normal : FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoWorkflowMessage() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: Colors.yellow.shade50,
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Center(
            child: Text('⚠️ No Workflow Configured',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.yellow.shade800)),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
          child: Center(
            child: Text('This requisition does not have an approval workflow configured.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600), textAlign: TextAlign.center),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkflowStatusHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Center(
        child: Text(' Workflow Approval Status',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue.shade800)),
      ),
    );
  }

  Widget _buildWorkflowSummaryRow() {
    final statistics = _workflowExecution?.statistics;
    final selectedWorkflow = _workflowExecution?.selectedWorkflow;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Template: ${selectedWorkflow?.templateName ?? "N/A"}',
              style: TextStyle(fontSize: 11, color: Colors.blue.shade600)),
          Text('Progress: ${statistics?.completedSteps ?? 0}/${statistics?.totalSteps ?? 0}',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade600)),
        ],
      ),
    );
  }

  Widget _buildWorkflowTimeline() {
    if (_workflowExecution?.workflowSteps.isEmpty ?? true) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _workflowExecution!.workflowSteps.length,
        itemBuilder: (context, index) {
          final step = _workflowExecution!.workflowSteps[index];
          final isLast = index == _workflowExecution!.workflowSteps.length - 1;
          return _buildTimelineStep(step, isLast);
        },
      ),
    );
  }

  Widget _buildTimelineStep(WorkflowStep step, bool isLast) {
    // Determine colors and icons based on status
    Color nodeColor;
    Color backgroundColor;
    Color borderColor;
    IconData statusIcon;
    String statusText;
    Color statusTextColor;
    
    if (step.outcome == 'approved') {
      nodeColor = Colors.green;
      backgroundColor = Colors.green.shade50;
      borderColor = Colors.green.shade200;
      statusIcon = Icons.check_circle;
      statusText = 'Completed';
      statusTextColor = Colors.green.shade700;
    } else if (step.outcome == 'rejected') {
      nodeColor = Colors.red;
      backgroundColor = Colors.red.shade50;
      borderColor = Colors.red.shade200;
      statusIcon = Icons.cancel;
      statusText = 'Rejected';
      statusTextColor = Colors.red.shade700;
    } else if (step.status == 'start' || step.status == 'in_progress') {
      nodeColor = Colors.blue;
      backgroundColor = Colors.blue.shade50;
      borderColor = Colors.blue.shade200;
      statusIcon = Icons.pending;
      statusText = 'In Progress';
      statusTextColor = Colors.blue.shade700;
    } else {
      nodeColor = Colors.grey;
      backgroundColor = Colors.grey.shade50;
      borderColor = Colors.grey.shade300;
      statusIcon = Icons.hourglass_empty;
      statusText = 'Pending';
      statusTextColor = Colors.grey.shade700;
    }

    // Format timestamps
    String formatTimestamp(String? timestamp) {
      if (timestamp == null || timestamp.isEmpty) return 'N/A';
      try {
        final dateTime = DateTime.parse(timestamp);
        return DateFormat('MMM d, hh:mm a').format(dateTime);
      } catch (e) {
        return timestamp;
      }
    }

    // Determine outcome display
    String outcomeDisplay = step.outcome != null && step.outcome!.isNotEmpty
        ? step.outcome!.substring(0, 1).toUpperCase() + step.outcome!.substring(1)
        : 'Pending';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline node
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: nodeColor, shape: BoxShape.circle),
              child: Icon(statusIcon, color: Colors.white, size: 16),
            ),
            if (!isLast) Container(width: 2, height: 80, color: Colors.grey.shade300),
          ],
        ),
        const SizedBox(width: 12),
        
        // Step details card
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step title and status badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Step ${step.stepOrder}: ${step.nodeDescription}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusTextColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusTextColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Detailed information in a single line
                Row(
                  children: [
                    // Approver
                    const SizedBox(width: 4),
                    Text(
                      'Approver:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      step.assignedTo ?? 'Not assigned',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black87,
                      ),
                    ),
                    
                    const SizedBox(width: 20),
                    
                    // Outcome
                   
                    const SizedBox(width: 4),
                    Text(
                      'Outcome:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      outcomeDisplay,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black87,
                      ),
                    ),
                    
                    const SizedBox(width: 20),
                    
                    // Started timestamp
                    
                    const SizedBox(width: 4),
                    Text(
                      'Started:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formatTimestamp(step.startDate?.toIso8601String()),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black87,
                      ),
                    ),
                    
                    const SizedBox(width: 20),
                    
                    // Completed timestamp
                    
                    const SizedBox(width: 4),
                    Text(
                      'Completed:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formatTimestamp(step.endDate?.toIso8601String()),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black87,
                      ),
                    ),
                    
                    const SizedBox(width: 20),
                    
                    // Approval position
                    
                    const SizedBox(width: 4),
                    Text(
                      'Approval:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Pos:${step.stepOrder}/${_workflowExecution?.workflowSteps.length ?? 0}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                
                // Comments section
                if (step.comments != null && step.comments!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(width: 6),
                      Text(
                        'Comments:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          step.comments!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade800,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  // Helper widget for step detail items
  Widget _buildStepDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
