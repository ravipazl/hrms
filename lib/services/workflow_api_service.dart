import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:dio/browser.dart';
import 'package:http/http.dart' as http;
import '../models/workflow_template.dart';
import '../models/workflow_node.dart';
import '../models/workflow_edge.dart';
import 'auth_service.dart';


class WorkflowApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  
  final Dio _dio;
  final AuthService _authService;
  
  WorkflowApiService({AuthService? authService}) 
    : _authService = authService ?? AuthService(),
      _dio = Dio() {
    _initializeDio();
  }

  void _initializeDio() {
    _dio.options.baseUrl = 'http://127.0.0.1:8000';
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    // CRITICAL: Enable credentials for Flutter Web (session cookies)
    _dio.options.extra['withCredentials'] = true;
    
    // Configure browser adapter for web
    final adapter = _dio.httpClientAdapter;
    if (adapter is BrowserHttpClientAdapter) {
      adapter.withCredentials = true;
    }
    
    // Timeouts
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    
    // Add interceptor to include CSRF token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Get CSRF token and add to headers
          final csrfToken = await _authService.getCsrfToken();
          if (csrfToken != null) {
            options.headers['X-CSRFToken'] = csrfToken;
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          print('❌ Workflow API Error: ${error.response?.statusCode} - ${error.message}');
          if (error.response?.statusCode == 403 || error.response?.statusCode == 401) {
            print('🔐 Authentication required - please login');
          }
          return handler.next(error);
        },
      ),
    );
    
    // Logging
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: false,
        requestHeader: true,
        responseHeader: true,
        logPrint: (obj) => print('🔄 [Workflow API] $obj'),
      ),
    );
  }


  /// Load all available workflow stages (PUBLIC - no auth required)
  Future<List<WorkflowStage>> loadStages() async {
    try {
      final response = await _dio.get('/api/workflow/stages/');

      if (response.statusCode == 200) {
        final data = response.data;
        
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
            .map((stage) => WorkflowStage.fromJson(stage as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load stages: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading stages: $e');
      return [];
    }
  }

  /// Load all available node types (PUBLIC - no auth required)
  Future<List<DatabaseNode>> loadAvailableNodes() async {
    try {
      final response = await _dio.get('/api/workflow/nodes/');

      if (response.statusCode == 200) {
        final data = response.data;
        
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
            .map((node) => DatabaseNode.fromJson(node as Map<String, dynamic>))
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

  /// Save workflow template (REQUIRES AUTH)
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

      Response templateResponse;
      if (template.id != null) {
        // Update existing template
        templateResponse = await _dio.put(
          '/api/workflow/templates/${template.id}/',
          data: templatePayload,
        );
      } else {
        // Create new template
        templateResponse = await _dio.post(
          '/api/workflow/templates/',
          data: templatePayload,
        );
      }

      if (templateResponse.statusCode != 200 &&
          templateResponse.statusCode != 201) {
        throw Exception('Failed to save template: ${templateResponse.statusCode}');
      }

      final savedTemplate = templateResponse.data;
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

      final layoutResponse = await _dio.post(
        '/api/workflow/templates/${savedTemplate['id']}/save_layout/',
        data: layoutPayload,
      );

      if (layoutResponse.statusCode != 200 &&
          layoutResponse.statusCode != 201) {
        throw Exception('Failed to save layout: ${layoutResponse.statusCode}');
      }

      final layoutResult = layoutResponse.data;
      print('✅ Layout saved successfully');

      return {
        ...savedTemplate as Map<String, dynamic>,
        'nodes_created': layoutResult['data']?['nodes_created'] ?? template.nodes.length,
        'edges_created': layoutResult['data']?['edges_created'] ?? template.edges.length,
      };
    } catch (e) {
      print('❌ Error saving workflow template: $e');
      rethrow;
    }
  }

  /// Load workflow template by ID (REQUIRES AUTH)
  Future<WorkflowTemplate> loadWorkflowTemplate(int templateId) async {
    try {
      final response = await _dio.get('/api/workflow/templates/$templateId/');

      if (response.statusCode == 200) {
        final data = response.data;
        return _convertDbTemplateToUiFormat(data);
      } else {
        throw Exception('Failed to load template: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading workflow template: $e');
      rethrow;
    }
  }

  /// Load all workflow templates (REQUIRES AUTH)
  Future<List<WorkflowTemplate>> loadWorkflowTemplates({int? stageId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (stageId != null) {
        queryParams['stage'] = stageId;
      }
      
      final response = await _dio.get(
        '/api/workflow/templates/',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
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
    print('🔍 Converting DB template to UI format...');
    print('   Template: ${dbTemplate['name']}');
    
    // ✅ EXACTLY like React: dbNode.node_details?.type === 'Stop'
    final List<WorkflowNode> uiNodes = (dbTemplate['nodes'] as List?)
            ?.map((dbNode) {
              try {
                // React: dbNode.node_details?.type === 'Stop' ? 'outcome' : 'approval'
                final nodeDetails = dbNode['node_details'] as Map<String, dynamic>?;
                final nodeType = (nodeDetails?['type'] == 'Stop') ? 'outcome' : 'approval';
                
                // React: dbNode.additional_info?.color || '#3B82F6'
                final additionalInfo = dbNode['additional_info'] as Map<String, dynamic>?;
                final colorStr = additionalInfo?['color'] ?? '#3B82F6';
                
                return WorkflowNode(
                  id: dbNode['node_instance_id'] ?? 'node-${dbNode['id']}',
                  type: nodeType,
                  position: Offset(
                    (dbNode['position_x'] ?? 400).toDouble(),
                    (dbNode['position_y'] ?? 280).toDouble(),
                  ),
                  data: WorkflowNodeData(
                    label: dbNode['description'] ?? '',
                    title: dbNode['description'] ?? '',
                    color: Color(int.parse(colorStr.replaceAll('#', '0xFF'))),
                    stepOrder: dbNode['node_order'] ?? 1,
                    
                    // React: dbNodeId: dbNode.node
                    dbNodeId: dbNode['node'],
                    
                    // React: nodeType: dbNode.additional_info?.node_type || dbNode.node_details?.display_name
                    nodeType: additionalInfo?['node_type'] ?? nodeDetails?['display_name'],
                    
                    // Employee details from additional_info
                    selectedEmployeeId: _parseToInt(additionalInfo?['emp_id']),
                    employeeEmail: additionalInfo?['email_id'],
                    username: additionalInfo?['username'],
                    employeeName: additionalInfo?['employee_name'],
                    userId: additionalInfo?['emp_id']?.toString(),
                    departmentId: additionalInfo?['department_id']?.toString(),
                    departmentName: additionalInfo?['department_name'],
                    
                    // React: outcome: dbNode.additional_info?.outcome
                    outcome: additionalInfo?['outcome'],
                    comment: additionalInfo?['comment'] ?? '',
                  ),
                );
              } catch (e) {
                print('❌ Error converting node: $e');
                print('   Node data: $dbNode');
                rethrow;
              }
            })
            .toList() ??
        [];

    // ✅ EXACTLY like React: Convert edges
    final List<WorkflowEdge> uiEdges = (dbTemplate['edges'] as List?)
            ?.map((dbEdge) {
              try {
                // React: source: dbEdge.start_node_details?.node_instance_id
                final startNodeDetails = dbEdge['start_node_details'] ?? dbEdge['start_node_instance'];
                final endNodeDetails = dbEdge['end_node_details'] ?? dbEdge['end_node_instance'];
                
                return WorkflowEdge(
                  id: 'edge-${dbEdge['id']}',
                  source: startNodeDetails['node_instance_id'],
                  target: endNodeDetails['node_instance_id'],
                  // React: label: dbEdge.outcome?.charAt(0).toUpperCase() + dbEdge.outcome?.slice(1)
                  label: _capitalizeFirst(dbEdge['outcome'] ?? 'Approved'),
                  type: 'straight',
                  data: dbEdge['edge_conditions'] as Map<String, dynamic>?,
                  order: dbEdge['edge_order'],
                  isStart: dbEdge['flow_start'],
                  isEnd: dbEdge['flow_end'],
                );
              } catch (e) {
                print('❌ Error converting edge: $e');
                print('   Edge data: $dbEdge');
                rethrow;
              }
            })
            .toList() ??
        [];

    print('✅ Converted: ${uiNodes.length} nodes, ${uiEdges.length} edges');

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
      departmentName: dbTemplate['department_name'],
      isGlobalDefault: dbTemplate['is_default'] ?? false,
      nodes: uiNodes,
      edges: uiEdges,
      templateMetadata: dbTemplate['template_metadata'] as Map<String, dynamic>?,
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

  /// Helper: Parse to int safely (handles both int and String)
  int? _parseToInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}
