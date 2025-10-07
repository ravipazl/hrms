/// Workflow Edge Model
/// Represents a connection between two nodes
class WorkflowEdge {
  final String id;
  final String source;
  final String target;
  final String label;
  final String type;
  final Map<String, dynamic>? data;
  final int? order;
  final bool? isStart;
  final bool? isEnd;

  WorkflowEdge({
    required this.id,
    required this.source,
    required this.target,
    required this.label,
    this.type = 'straight',
    this.data,
    this.order,
    this.isStart,
    this.isEnd,
  });

  factory WorkflowEdge.fromJson(Map<String, dynamic> json) {
    return WorkflowEdge(
      id: json['id'] ?? '',
      source: json['source'] ?? '',
      target: json['target'] ?? '',
      label: json['label'] ?? 'Proceed',
      type: json['type'] ?? 'straight',
      data: json['data'],
      order: json['order'],
      isStart: json['isStart'],
      isEnd: json['isEnd'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source': source,
      'target': target,
      'label': label,
      'type': type,
      'data': data,
      'order': order,
      'isStart': isStart,
      'isEnd': isEnd,
    };
  }

  WorkflowEdge copyWith({
    String? id,
    String? source,
    String? target,
    String? label,
    String? type,
    Map<String, dynamic>? data,
    int? order,
    bool? isStart,
    bool? isEnd,
  }) {
    return WorkflowEdge(
      id: id ?? this.id,
      source: source ?? this.source,
      target: target ?? this.target,
      label: label ?? this.label,
      type: type ?? this.type,
      data: data ?? this.data,
      order: order ?? this.order,
      isStart: isStart ?? this.isStart,
      isEnd: isEnd ?? this.isEnd,
    );
  }
}
