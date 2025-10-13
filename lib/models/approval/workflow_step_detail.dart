// lib/models/approval/workflow_step_detail.dart

import 'package:flutter/material.dart';

/// Workflow Step Detail Model
/// Contains all information needed for approval action
class WorkflowStepDetail {
  final int id;
  final String requisitionId;
  final String jobPosition;
  final String? departmentName;
  final String? jobDescription;
  final String? qualification;
  final String? experience;
  final String? preferredGenderName;
  final String? preferredAgeGroup;
  final String workflowNodeDescription;
  final String templateName;
  final int selectedWorkflowId;
  final int workflowNode;
  final String assignedTo;
  final DateTime? startDate;
  final String? statusName;
  final List<PositionDetail> positions;

  WorkflowStepDetail({
    required this.id,
    required this.requisitionId,
    required this.jobPosition,
    this.departmentName,
    this.jobDescription,
    this.qualification,
    this.experience,
    this.preferredGenderName,
    this.preferredAgeGroup,
    required this.workflowNodeDescription,
    required this.templateName,
    required this.selectedWorkflowId,
    required this.workflowNode,
    required this.assignedTo,
    this.startDate,
    this.statusName,
    this.positions = const [],
  });

  factory WorkflowStepDetail.fromJson(Map<String, dynamic> json) {
    return WorkflowStepDetail(
      id: json['id'] ?? 0,
      requisitionId: json['requisition_id']?.toString() ?? '',
      jobPosition: json['job_position']?.toString() ?? '',
      departmentName: json['department_name']?.toString(),
      jobDescription: json['job_description']?.toString(),
      qualification: json['qualification']?.toString(),
      experience: json['experience']?.toString(),
      preferredGenderName: json['preferred_gender_name']?.toString(),
      preferredAgeGroup: json['preferred_age_group']?.toString(),
      workflowNodeDescription: json['workflow_node_description']?.toString() ?? '',
      templateName: json['template_name']?.toString() ?? '',
      selectedWorkflowId: json['selected_workflow_id'] ?? 0,
      workflowNode: json['workflow_node'] ?? 0,
      assignedTo: json['assigned_to']?.toString() ?? '',
      startDate: json['start_date'] != null 
          ? DateTime.tryParse(json['start_date']) 
          : null,
      statusName: json['status_name']?.toString(),
      positions: (json['positions'] as List?)
              ?.map((pos) => PositionDetail.fromJson(pos))
              .toList() ??
          [],
    );
  }
}

/// Position Detail Model for Approval
class PositionDetail {
  final int id;
  final int requisitionQuantity;
  final int approvedHead;
  final String? typeRequisitionName;
  final String? employmentTypeName;
  final String? employeeName;
  final String? employeeNo;
  final String? dateOfResignation;
  final String? resignationReason;
  final String? justificationText;

  PositionDetail({
    required this.id,
    required this.requisitionQuantity,
    this.approvedHead = 0,
    this.typeRequisitionName,
    this.employmentTypeName,
    this.employeeName,
    this.employeeNo,
    this.dateOfResignation,
    this.resignationReason,
    this.justificationText,
  });

  factory PositionDetail.fromJson(Map<String, dynamic> json) {
    return PositionDetail(
      id: json['id'] ?? 0,
      requisitionQuantity: json['requisition_quantity'] ?? 0,
      approvedHead: json['approved_head'] ?? 0,
      typeRequisitionName: json['type_requisition_name']?.toString(),
      employmentTypeName: json['employment_type_name']?.toString(),
      employeeName: json['employee_name']?.toString(),
      employeeNo: json['employee_no']?.toString(),
      dateOfResignation: json['date_of_resignation']?.toString(),
      resignationReason: json['resignation_reason']?.toString(),
      justificationText: json['justification_text']?.toString(),
    );
  }
}

/// Action Outcome Model (Dynamic actions from DB)
class ActionOutcome {
  final String value;   // 'approved', 'rejected', 'hold', etc.
  final String label;   // 'Approved', 'Rejected', 'Hold'
  final Color color;
  final String icon;

  ActionOutcome({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });
}

/// Position Approval Model (for partial approval)
class PositionApproval {
  final int positionId;
  final int requisitionQuantity;
  final int approvedHead;
  final int pending;
  int approvedCount;
  final int maxAllowed;
  final String typeRequisitionName;

  PositionApproval({
    required this.positionId,
    required this.requisitionQuantity,
    required this.approvedHead,
    required this.pending,
    this.approvedCount = 0,
    required this.maxAllowed,
    required this.typeRequisitionName,
  });

  // Validation
  bool get isValid => approvedCount >= 0 && approvedCount <= maxAllowed;
  bool get hasError => approvedCount > maxAllowed;
}
