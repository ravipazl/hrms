import 'package:flutter_test/flutter_test.dart';
import 'package:hrms/models/workflow_node.dart';
import 'package:hrms/models/workflow_edge.dart';
import 'package:hrms/models/workflow_template.dart';
import 'package:flutter/material.dart';

void main() {
  group('Workflow Models', () {
    test('WorkflowNode creation', () {
      final node = WorkflowNode(
        id: 'test-1',
        type: 'approval',
        position: const Offset(100, 100),
        data: WorkflowNodeData(
          label: 'Test Node',
          title: 'Test Node',
          color: Colors.blue,
          stepOrder: 1,
        ),
      );

      expect(node.id, 'test-1');
      expect(node.type, 'approval');
      expect(node.position.dx, 100);
      expect(node.data.label, 'Test Node');
    });

    test('WorkflowEdge creation', () {
      final edge = WorkflowEdge(
        id: 'edge-1',
        source: 'node-1',
        target: 'node-2',
        label: 'Approved',
      );

      expect(edge.id, 'edge-1');
      expect(edge.source, 'node-1');
      expect(edge.target, 'node-2');
      expect(edge.label, 'Approved');
    });

    test('WorkflowTemplate creation', () {
      final template = WorkflowTemplate(
        name: 'Test Template',
        description: 'Test Description',
        stage: 'Requisition',
        nodes: [],
        edges: [],
      );

      expect(template.name, 'Test Template');
      expect(template.description, 'Test Description');
      expect(template.nodes.length, 0);
    });
  });
}
