import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/workflow_template.dart';
import '../models/workflow_node.dart';
import '../models/workflow_edge.dart';

class WorkflowApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  /// Load all available workflow stages
  Future<List<WorkflowStage>> loadStages() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/workflow/stages/'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        List<dynamic> stagesList;
        if (data is List) {
          stagesList = data;
        } else if (data['results'] != null) {
          stagesList = data['results'];
        } else if (data['data'] != null) {
          stagesList = data['data'];
        } else {
          throw Exception('Invalid stage data format');
        }

        return stagesList
            .map((stage) => WorkflowStage.fromJson(stage))
            .toList();
      } else {
        throw Exception('Failed to load stages: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading stages: $e');
      return [];
    }
  }

  /// Load all available node types
  Future<List<DatabaseNode>> loadAvailableNodes() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/workflow/nodes/'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        List<dynamic> nodesList;
        if (data is List) {
          nodesList = data;
        } else if (data['results'] != null) {
          nodesList = data['results'];
        } else if (data['data'] != null) {
          nodesList = data['data'];
        } else {
          throw Exception('Invalid nodes data format');
        }

        return nodesList
            .map((node) => DatabaseNode.fromJson(node))
            .toList();
      } else {
        throw Exception('Failed to load nodes: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading nodes: $e');
      return [];
    }
  }

  /// Load node constraints for a specific stage
  Future<List<StageNodeConstraint>> loadStageNodes(int stageId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/workflow/stage-nodes/?stage=$stageId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        List<dynamic> constraintsList;
        if (data is List) {
          constraintsList = data;
        } else if (data['results'] != null) {
          constraintsList = data['results'];
        } else if (data['data'] != null) {
          constraintsList = data['data'];
        } else {
          throw Exception('Invalid stage nodes data format');
        }

        // Transform the API response to match expected format
        return constraintsList.map((item) {
          return StageNodeConstraint.fromJson({
            ...item,
            'node': {
              'id': item['node'],
              'display_name': item['node_name'],
              'name': item['node_name'],
              'type': item['node_type'],
              'description': '',
            }
          });
        }).toList();
      } else {
        throw Exception('Failed to load stage nodes: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading stage nodes: $e');
      return [];
    }
  }

  /// Save workflow template
  Future<Map<String, dynamic>> saveWorkflowTemplate(
      WorkflowTemplate template) async {
    try {
      print('💾 Saving workflow template: ${template.name}');

      // Step 1: Create or update template
      final templatePayload = {
        'stage': template.selectedStage?.id ?? 1,
        'name': template.name,
        'description': template.description,
        'department': template.department,
        'is_default': template.isGlobalDefault,
        'template_metadata': {
          'canvas_size': {'width': 2200, 'height': 1400},
          'workflow_type': 'custom',
        }
      };

      http.Response templateResponse;
      if (template.id != null) {
        // Update existing template
        templateResponse = await http.put(
          Uri.parse('$baseUrl/workflow/templates/${template.id}/'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(templatePayload),
        );
      } else {
        // Create new template
        templateResponse = await http.post(
          Uri.parse('$baseUrl/workflow/templates/'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(templatePayload),
        );
      }

      if (templateResponse.statusCode != 200 &&
          templateResponse.statusCode != 201) {
        throw Exception('Failed to save template: ${templateResponse.statusCode}');
      }

      final savedTemplate = json.decode(templateResponse.body);
      print('✅ Template saved: ${savedTemplate['id']}');

      // Step 2: Save layout (nodes and edges)
      final layoutPayload = {
        'template_metadata': templatePayload['template_metadata'],
        'nodes': template.nodes.map((node) {
          return {
            'node': node.data.dbNodeId,
            'description': node.data.label,
            'node_instance_id': node.id,
            'position_x': node.position.dx,
            'position_y': node.position.dy,
            'node_order': node.data.stepOrder,
            'additional_info': {
              'emp_id': node.data.selectedEmployeeId?.toString() ?? '',
              'email_id': node.data.employeeEmail ?? '',
              'username': node.data.username ?? '',
              'employee_name': node.data.employeeName ?? '',
              'department_id': node.data.departmentId ?? '',
              'department_name': node.data.departmentName ?? '',
              'color': '#${node.data.color.value.toRadixString(16).substring(2)}',
              'node_type': node.data.nodeType ?? node.type,
              'outcome': node.data.outcome,
            }
          };
        }).toList(),
        'edges': template.edges.map((edge) {
          return {
            'start_node_instance_id': edge.source,
            'end_node_instance_id': edge.target,
            'outcome': edge.data?['condition'] ?? edge.label.toLowerCase(),
            'flow_start': _isFlowStart(edge, template.edges),
            'flow_end': _isFlowEnd(edge, template.edges),
            'edge_conditions': edge.data ?? {},
            'edge_order': edge.order ?? 0,
          };
        }).toList(),
      };

      final layoutResponse = await http.post(
        Uri.parse('$baseUrl/workflow/templates/${savedTemplate['id']}/save_layout/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(layoutPayload),
      );

      if (layoutResponse.statusCode != 200 &&
          layoutResponse.statusCode != 201) {
        throw Exception('Failed to save layout: ${layoutResponse.statusCode}');
      }

      final layoutResult = json.decode(layoutResponse.body);
      print('✅ Layout saved successfully');

      return {
        ...savedTemplate,
        'nodes_created': layoutResult['data']?['nodes_created'] ?? template.nodes.length,
        'edges_created': layoutResult['data']?['edges_created'] ?? template.edges.length,
      };
    } catch (e) {
      print('❌ Error saving workflow template: $e');
      rethrow;
    }
  }

  /// Load workflow template by ID
  Future<WorkflowTemplate> loadWorkflowTemplate(int templateId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/workflow/templates/$templateId/'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _convertDbTemplateToUiFormat(data);
      } else {
        throw Exception('Failed to load template: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading workflow template: $e');
      rethrow;
    }
  }

  /// Load all workflow templates
  Future<List<WorkflowTemplate>> loadWorkflowTemplates({int? stageId}) async {
    try {
      final url = stageId != null
          ? '$baseUrl/workflow/templates/?stage=$stageId'
          : '$baseUrl/workflow/templates/';
      
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        List<dynamic> templatesList;
        if (data is List) {
          templatesList = data;
        } else if (data['results'] != null) {
          templatesList = data['results'];
        } else {
          throw Exception('Invalid templates data format');
        }

        return templatesList
            .map((template) => _convertDbTemplateToUiFormat(template))
            .toList();
      } else {
        throw Exception('Failed to load templates: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading workflow templates: $e');
      return [];
    }
  }

  /// Helper: Check if edge is flow start
  bool _isFlowStart(WorkflowEdge edge, List<WorkflowEdge> allEdges) {
    return !allEdges.any((e) => e.target == edge.source);
  }

  /// Helper: Check if edge is flow end
  bool _isFlowEnd(WorkflowEdge edge, List<WorkflowEdge> allEdges) {
    return !allEdges.any((e) => e.source == edge.target);
  }

  /// Helper: Convert database template format to UI format
  WorkflowTemplate _convertDbTemplateToUiFormat(Map<String, dynamic> dbTemplate) {
    // Convert nodes
    final List<WorkflowNode> uiNodes = (dbTemplate['nodes'] as List?)
            ?.map((dbNode) {
              final nodeType = _mapDbNodeTypeToUiType(dbNode['node']['type']);
              return WorkflowNode(
                id: dbNode['node_instance_id'],
                type: nodeType,
                position: Offset(
                  (dbNode['position_x'] ?? 400).toDouble(),
                  (dbNode['position_y'] ?? 280).toDouble(),
                ),
                data: WorkflowNodeData(
                  label: dbNode['description'] ?? '',
                  title: dbNode['description'] ?? '',
                  color: Color(int.parse(
                    dbNode['additional_info']?['color']
                            ?.replaceAll('#', '0xFF') ??
                        '0xFF3B82F6',
                  )),
                  stepOrder: dbNode['node_order'] ?? 1,
                  dbNodeId: dbNode['node'],
                  nodeType: dbNode['additional_info']?['node_type'],
                  selectedEmployeeId: int.tryParse(
                      dbNode['additional_info']?['emp_id']?.toString() ?? ''),
                  employeeEmail: dbNode['additional_info']?['email_id'],
                  username: dbNode['additional_info']?['username'],
                  employeeName: dbNode['additional_info']?['employee_name'],
                  departmentId: dbNode['additional_info']?['department_id'],
                  departmentName: dbNode['additional_info']?['department_name'],
                  outcome: _mapDbNodeTypeToOutcome(dbNode['node']['type']),
                ),
              );
            })
            .toList() ??
        [];

    // Convert edges
    final List<WorkflowEdge> uiEdges = (dbTemplate['edges'] as List?)
            ?.map((dbEdge) {
              return WorkflowEdge(
                id: 'edge-${dbEdge['id']}',
                source: dbEdge['start_node_instance']['node_instance_id'],
                target: dbEdge['end_node_instance']['node_instance_id'],
                label: _capitalizeFirst(dbEdge['outcome'] ?? 'Approved'),
                type: 'straight',
                data: dbEdge['edge_conditions'],
                order: dbEdge['edge_order'],
                isStart: dbEdge['flow_start'],
                isEnd: dbEdge['flow_end'],
              );
            })
            .toList() ??
        [];

    return WorkflowTemplate(
      id: dbTemplate['id'],
      name: dbTemplate['name'] ?? '',
      description: dbTemplate['description'] ?? '',
      stage: dbTemplate['stage_name'] ?? 'Requisition',
      selectedStage: WorkflowStage(
        id: dbTemplate['stage'],
        name: dbTemplate['stage_name'] ?? '',
        description: dbTemplate['stage_name'] ?? '',
      ),
      department: dbTemplate['department'],
      isGlobalDefault: dbTemplate['is_default'] ?? false,
      nodes: uiNodes,
      edges: uiEdges,
      templateMetadata: dbTemplate['template_metadata'],
      createdAt: DateTime.tryParse(dbTemplate['created_at'] ?? ''),
      updatedAt: DateTime.tryParse(dbTemplate['updated_at'] ?? ''),
    );
  }

  /// Helper: Map database node type to UI type
  String _mapDbNodeTypeToUiType(String dbNodeType) {
    const typeMapping = {
      'Process': 'approval',
      'Stop': 'outcome',
      'Start': 'approval',
      'Decision': 'approval',
      'Input': 'approval',
      'Output': 'outcome',
    };
    return typeMapping[dbNodeType] ?? 'approval';
  }

  /// Helper: Map database node type to outcome
  String? _mapDbNodeTypeToOutcome(String dbNodeType) {
    if (dbNodeType == 'Stop') {
      return 'approved';
    }
    return null;
  }

  /// Helper: Capitalize first letter
  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
