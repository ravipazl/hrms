import 'package:flutter/material.dart';

/// Workflow Node Model
/// Represents a node in the workflow (approval or outcome)
class WorkflowNode {
  final String id;
  final String type; // 'approval' or 'outcome'
  final Offset position;
  final WorkflowNodeData data;

  WorkflowNode({
    required this.id,
    required this.type,
    required this.position,
    required this.data,
  });

  factory WorkflowNode.fromJson(Map<String, dynamic> json) {
    return WorkflowNode(
      id: json['id'] ?? '',
      type: json['type'] ?? 'approval',
      position: Offset(
        (json['position']?['x'] ?? 0).toDouble(),
        (json['position']?['y'] ?? 0).toDouble(),
      ),
      data: WorkflowNodeData.fromJson(json['data'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'position': {
        'x': position.dx,
        'y': position.dy,
      },
      'data': data.toJson(),
    };
  }

  WorkflowNode copyWith({
    String? id,
    String? type,
    Offset? position,
    WorkflowNodeData? data,
  }) {
    return WorkflowNode(
      id: id ?? this.id,
      type: type ?? this.type,
      position: position ?? this.position,
      data: data ?? this.data,
    );
  }
}

/// Node Data Model
class WorkflowNodeData {
  final String label;
  final String title;
  final Color color;
  final int stepOrder;
  final int? dbNodeId;
  final String? nodeType;
  final String? username;
  final String? userId;
  final String? employeeName;
  final String? employeeEmail;
  final String? comment;
  final String? outcome;
  final bool isRequired;
  final int? selectedEmployeeId;
  final String? employeePhone;
  final String? badgeId;
  final String? departmentId;
  final String? departmentName;

  WorkflowNodeData({
    required this.label,
    required this.title,
    required this.color,
    this.stepOrder = 1,
    this.dbNodeId,
    this.nodeType,
    this.username,
    this.userId,
    this.employeeName,
    this.employeeEmail,
    this.comment,
    this.outcome,
    this.isRequired = false,
    this.selectedEmployeeId,
    this.employeePhone,
    this.badgeId,
    this.departmentId,
    this.departmentName,
  });

  factory WorkflowNodeData.fromJson(Map<String, dynamic> json) {
    return WorkflowNodeData(
      label: json['label'] ?? '',
      title: json['title'] ?? '',
      color: Color(int.parse(
        json['color']?.replaceAll('#', '0xFF') ?? '0xFF3B82F6',
      )),
      stepOrder: json['stepOrder'] ?? 1,
      dbNodeId: json['dbNodeId'],
      nodeType: json['nodeType'],
      username: json['username'],
      userId: json['userId'],
      employeeName: json['employeeName'],
      employeeEmail: json['employeeEmail'],
      comment: json['comment'],
      outcome: json['outcome'],
      isRequired: json['isRequired'] ?? false,
      selectedEmployeeId: json['selectedEmployeeId'],
      employeePhone: json['employeePhone'],
      badgeId: json['badgeId'],
      departmentId: json['departmentId'],
      departmentName: json['departmentName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'title': title,
      'color': '#${color.value.toRadixString(16).substring(2)}',
      'stepOrder': stepOrder,
      'dbNodeId': dbNodeId,
      'nodeType': nodeType,
      'username': username,
      'userId': userId,
      'employeeName': employeeName,
      'employeeEmail': employeeEmail,
      'comment': comment,
      'outcome': outcome,
      'isRequired': isRequired,
      'selectedEmployeeId': selectedEmployeeId,
      'employeePhone': employeePhone,
      'badgeId': badgeId,
      'departmentId': departmentId,
      'departmentName': departmentName,
    };
  }

  WorkflowNodeData copyWith({
    String? label,
    String? title,
    Color? color,
    int? stepOrder,
    int? dbNodeId,
    String? nodeType,
    String? username,
    String? userId,
    String? employeeName,
    String? employeeEmail,
    String? comment,
    String? outcome,
    bool? isRequired,
    int? selectedEmployeeId,
    String? employeePhone,
    String? badgeId,
    String? departmentId,
    String? departmentName,
  }) {
    return WorkflowNodeData(
      label: label ?? this.label,
      title: title ?? this.title,
      color: color ?? this.color,
      stepOrder: stepOrder ?? this.stepOrder,
      dbNodeId: dbNodeId ?? this.dbNodeId,
      nodeType: nodeType ?? this.nodeType,
      username: username ?? this.username,
      userId: userId ?? this.userId,
      employeeName: employeeName ?? this.employeeName,
      employeeEmail: employeeEmail ?? this.employeeEmail,
      comment: comment ?? this.comment,
      outcome: outcome ?? this.outcome,
      isRequired: isRequired ?? this.isRequired,
      selectedEmployeeId: selectedEmployeeId ?? this.selectedEmployeeId,
      employeePhone: employeePhone ?? this.employeePhone,
      badgeId: badgeId ?? this.badgeId,
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
    );
  }
}
