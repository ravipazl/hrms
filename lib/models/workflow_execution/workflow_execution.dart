// lib/models/workflow_execution/workflow_execution.dart

/// Workflow Execution Model - Represents active workflow instance
class WorkflowExecution {
  final int? id;
  final bool workflowConfigured;
  final String? workflowStatus;
  final SelectedWorkflow? selectedWorkflow;
  final List<WorkflowStep> workflowSteps;
  final WorkflowStatistics? statistics;

  WorkflowExecution({
    this.id,
    required this.workflowConfigured,
    this.workflowStatus,
    this.selectedWorkflow,
    this.workflowSteps = const [],
    this.statistics,
  });

  factory WorkflowExecution.fromJson(Map<String, dynamic> json) {
    return WorkflowExecution(
      id: json['id'],
      workflowConfigured: json['workflow_configured'] ?? false,
      workflowStatus: json['workflow_status'],
      selectedWorkflow: json['selected_workflow'] != null
          ? SelectedWorkflow.fromJson(json['selected_workflow'])
          : null,
      workflowSteps: (json['workflow_steps'] as List?)
              ?.map((step) => WorkflowStep.fromJson(step))
              .toList() ??
          [],
      statistics: json['statistics'] != null
          ? WorkflowStatistics.fromJson(json['statistics'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workflow_configured': workflowConfigured,
      'workflow_status': workflowStatus,
      'selected_workflow': selectedWorkflow?.toJson(),
      'workflow_steps': workflowSteps.map((step) => step.toJson()).toList(),
      'statistics': statistics?.toJson(),
    };
  }
}

/// Selected Workflow - The workflow template instance assigned to requisition
class SelectedWorkflow {
  final int id;
  final int requisitionId;
  final int workflowTemplateId;
  final String? templateName;
  final String? stage;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SelectedWorkflow({
    required this.id,
    required this.requisitionId,
    required this.workflowTemplateId,
    this.templateName,
    this.stage,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory SelectedWorkflow.fromJson(Map<String, dynamic> json) {
    return SelectedWorkflow(
      id: json['id'] ?? 0,
      requisitionId: json['requisition_id'] ?? json['requisition'] ?? 0,
      workflowTemplateId: json['workflow_template_id'] ?? json['workflow_template'] ?? 0,
      templateName: json['template_name'],
      stage: json['stage'],
      status: json['status'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requisition_id': requisitionId,
      'workflow_template_id': workflowTemplateId,
      'template_name': templateName,
      'stage': stage,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

/// Workflow Step - Individual step in the workflow execution
class WorkflowStep {
  final int id;
  final int workflowId;
  final String nodeDescription;
  final int stepOrder;
  final String? status; // 'start', 'end', null (pending)
  final String? outcome; // 'approved', 'rejected', 'hold'
  final String? assignedTo;
  final String? comments;
  final DateTime? startDate;
  final DateTime? endDate;

  WorkflowStep({
    required this.id,
    required this.workflowId,
    required this.nodeDescription,
    required this.stepOrder,
    this.status,
    this.outcome,
    this.assignedTo,
    this.comments,
    this.startDate,
    this.endDate,
  });

  factory WorkflowStep.fromJson(Map<String, dynamic> json) {
    return WorkflowStep(
      id: json['id'] ?? 0,
      workflowId: json['workflow_id'] ?? json['workflow'] ?? 0,
      nodeDescription: json['node_description'] ?? json['description'] ?? '',
      stepOrder: json['step_order'] ?? 0,
      status: json['status'],
      outcome: json['outcome'],
      assignedTo: json['assigned_to'],
      comments: json['comments'],
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workflow_id': workflowId,
      'node_description': nodeDescription,
      'step_order': stepOrder,
      'status': status,
      'outcome': outcome,
      'assigned_to': assignedTo,
      'comments': comments,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
    };
  }
}

/// Workflow Statistics - Progress tracking
class WorkflowStatistics {
  final int totalSteps;
  final int completedSteps;
  final int pendingSteps;
  final double completionPercentage;

  WorkflowStatistics({
    required this.totalSteps,
    required this.completedSteps,
    required this.pendingSteps,
    required this.completionPercentage,
  });

  factory WorkflowStatistics.fromJson(Map<String, dynamic> json) {
    return WorkflowStatistics(
      totalSteps: json['total_steps'] ?? 0,
      completedSteps: json['completed_steps'] ?? 0,
      pendingSteps: json['pending_steps'] ?? 0,
      completionPercentage: (json['completion_percentage'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_steps': totalSteps,
      'completed_steps': completedSteps,
      'pending_steps': pendingSteps,
      'completion_percentage': completionPercentage,
    };
  }
}
