import 'workflow_node.dart';
import 'workflow_edge.dart';

/// Workflow Template Model
/// Represents a complete workflow template
class WorkflowTemplate {
  final int? id;
  final String name;
  final String description;
  final String stage;
  final WorkflowStage? selectedStage;
  final int? department;
  final bool isGlobalDefault;
  final List<WorkflowNode> nodes;
  final List<WorkflowEdge> edges;
  final Map<String, dynamic>? templateMetadata;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WorkflowTemplate({
    this.id,
    required this.name,
    required this.description,
    required this.stage,
    this.selectedStage,
    this.department,
    this.isGlobalDefault = false,
    required this.nodes,
    required this.edges,
    this.templateMetadata,
    this.createdAt,
    this.updatedAt,
  });

  factory WorkflowTemplate.fromJson(Map<String, dynamic> json) {
    return WorkflowTemplate(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      stage: json['stage'] ?? '',
      selectedStage: json['selectedStage'] != null
          ? WorkflowStage.fromJson(json['selectedStage'])
          : null,
      department: json['department'],
      isGlobalDefault: json['isGlobalDefault'] ?? false,
      nodes: (json['nodes'] as List?)
              ?.map((node) => WorkflowNode.fromJson(node))
              .toList() ??
          [],
      edges: (json['edges'] as List?)
              ?.map((edge) => WorkflowEdge.fromJson(edge))
              .toList() ??
          [],
      templateMetadata: json['template_metadata'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'stage': stage,
      'selectedStage': selectedStage?.toJson(),
      'department': department,
      'isGlobalDefault': isGlobalDefault,
      'nodes': nodes.map((node) => node.toJson()).toList(),
      'edges': edges.map((edge) => edge.toJson()).toList(),
      'template_metadata': templateMetadata,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  WorkflowTemplate copyWith({
    int? id,
    String? name,
    String? description,
    String? stage,
    WorkflowStage? selectedStage,
    int? department,
    bool? isGlobalDefault,
    List<WorkflowNode>? nodes,
    List<WorkflowEdge>? edges,
    Map<String, dynamic>? templateMetadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkflowTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      stage: stage ?? this.stage,
      selectedStage: selectedStage ?? this.selectedStage,
      department: department ?? this.department,
      isGlobalDefault: isGlobalDefault ?? this.isGlobalDefault,
      nodes: nodes ?? this.nodes,
      edges: edges ?? this.edges,
      templateMetadata: templateMetadata ?? this.templateMetadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Workflow Stage Model
class WorkflowStage {
  final int id;
  final String name;
  final String description;

  WorkflowStage({
    required this.id,
    required this.name,
    required this.description,
  });

  factory WorkflowStage.fromJson(Map<String, dynamic> json) {
    return WorkflowStage(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }
}

/// Database Node Type Model
class DatabaseNode {
  final int id;
  final String name;
  final String displayName;
  final String type; // 'Process' or 'Stop'
  final String description;

  DatabaseNode({
    required this.id,
    required this.name,
    required this.displayName,
    required this.type,
    required this.description,
  });

  factory DatabaseNode.fromJson(Map<String, dynamic> json) {
    return DatabaseNode(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      displayName: json['display_name'] ?? '',
      type: json['type'] ?? 'Process',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'display_name': displayName,
      'type': type,
      'description': description,
    };
  }
}

/// Stage Node Constraint Model
class StageNodeConstraint {
  final int id;
  final int stage;
  final DatabaseNode node;
  final int minCount;
  final int maxCount;
  final String stageName;
  final String nodeName;
  final String nodeType;

  StageNodeConstraint({
    required this.id,
    required this.stage,
    required this.node,
    required this.minCount,
    required this.maxCount,
    required this.stageName,
    required this.nodeName,
    required this.nodeType,
  });

  factory StageNodeConstraint.fromJson(Map<String, dynamic> json) {
    return StageNodeConstraint(
      id: json['id'] ?? 0,
      stage: json['stage'] ?? 0,
      node: DatabaseNode.fromJson(json['node'] ?? {}),
      minCount: json['min_count'] ?? 0,
      maxCount: json['max_count'] ?? 1,
      stageName: json['stage_name'] ?? '',
      nodeName: json['node_name'] ?? '',
      nodeType: json['node_type'] ?? 'Process',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stage': stage,
      'node': node.toJson(),
      'min_count': minCount,
      'max_count': maxCount,
      'stage_name': stageName,
      'node_name': nodeName,
      'node_type': nodeType,
    };
  }
}
