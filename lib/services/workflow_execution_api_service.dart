// lib/services/workflow_execution_api_service.dart
// ✅ FIXED: Use same approach as workflow_api_service.dart (plain http with no auth)

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/workflow_execution/workflow_execution.dart';
import '../models/workflow_template.dart';

class WorkflowExecutionApiService {
  // FIXED: Match React implementation - use /api/v1 instead of /api
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  /// Get workflow execution status for a requisition
  /// FIXED: Match React implementation endpoint path
  Future<Map<String, dynamic>> getWorkflowExecutionStatus(int requisitionId) async {
    try {
      print('🔍 Loading workflow execution status for requisition: $requisitionId');
      
      // FIXED: Match React endpoint - /workflow/requisition/{id}/execution-status/
      final response = await http.get(
        Uri.parse('$baseUrl/workflow/requisition/$requisitionId/execution-status/'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'success' && data['data'] != null) {
          print('✅ Workflow execution data loaded');
          return {
            'status': 'success',
            'data': WorkflowExecution.fromJson(data['data'])
          };
        } else {
          print('⚠️ No workflow execution found');
          return {
            'status': 'success',
            'data': WorkflowExecution(workflowConfigured: false)
          };
        }
      } else {
        throw Exception('Failed to load workflow execution: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading workflow execution status: $e');
      return {
        'status': 'error',
        'message': e.toString(),
        'data': WorkflowExecution(workflowConfigured: false)
      };
    }
  }

  /// Get available workflow templates (filtered by department if provided)
  Future<List<WorkflowTemplate>> getAvailableTemplates({int? departmentId}) async {
    try {
      print('📋 Loading workflow templates...');
      
      String url = '$baseUrl/workflow/templates/';
      if (departmentId != null) {
        url += '?department=$departmentId';
        print('🏢 Filtering by department ID: $departmentId');
      }
      
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        print('📝 Raw API Response type: ${data.runtimeType}');
        if (data is Map) {
          print('📝 Response keys: ${data.keys.toList()}');
        }
        
        List<dynamic> templatesList;
        if (data is List) {
          templatesList = data;
          print('📝 Templates is a direct List with ${data.length} items');
        } else if (data['results'] != null) {
          templatesList = data['results'];
          print('📝 Templates in results field with ${data['results'].length} items');
        } else if (data['data'] != null) {
          templatesList = data['data'];
          print('📝 Templates in data field with ${data['data'].length} items');
        } else {
          throw Exception('Invalid templates data format');
        }

        // Parse each template with detailed error logging
        final templates = <WorkflowTemplate>[];
        for (int i = 0; i < templatesList.length; i++) {
          try {
            print('📝 Parsing template $i: ${templatesList[i]['name']}');
            final template = WorkflowTemplate.fromJson(templatesList[i]);
            templates.add(template);
            print('   ✅ Successfully parsed template: ${template.name}');
          } catch (templateError) {
            print('❌ Error parsing template $i: $templateError');
            print('📝 Template data: ${templatesList[i]}');
            // Continue parsing other templates instead of throwing
          }
        }
            
        print('✅ Loaded ${templates.length} workflow templates successfully');
        return templates;
      } else {
        throw Exception('Failed to load templates: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading workflow templates: $e');
      print('📝 Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  /// ✅ FIXED: Update requisition status - EXACTLY like workflow_api_service.dart
  Future<Map<String, dynamic>> updateRequisitionStatus(
    int requisitionId,
    String status,
  ) async {
    try {
      print('🔄 Updating requisition $requisitionId status to: $status');
      print('📍 Endpoint: PATCH $baseUrl/requisition/$requisitionId/status/');
      
      // ✅ EXACTLY like workflow_api_service.dart - plain http with only Content-Type
      final response = await http.patch(
        Uri.parse('$baseUrl/requisition/$requisitionId/status/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': status}),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Status updated successfully');
        return {
          'success': true,
          'message': 'Status updated to $status successfully',
          'status': data['status'] ?? status
        };
      } else {
        final errorData = json.decode(response.body);
        print('❌ Status update failed: $errorData');
        throw Exception(errorData['message'] ?? errorData['error'] ?? 'Failed to update status');
      }
    } catch (e) {
      print('❌ Error updating status: $e');
      return {
        'success': false,
        'message': e.toString()
      };
    }
  }

  /// Trigger workflow execution (create selected_workflow + workflow_steps)
  Future<Map<String, dynamic>> triggerWorkflowExecution({
    required int requisitionId,
    required int workflowTemplateId,
  }) async {
    try {
      print('🚀 Triggering workflow execution');
      print('   - Requisition ID: $requisitionId');
      print('   - Template ID: $workflowTemplateId');
      
      // ✅ EXACTLY like workflow_api_service.dart
      final response = await http.post(
        Uri.parse('$baseUrl/workflow/trigger-execution/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'requisition_id': requisitionId,
          'workflow_template_id': workflowTemplateId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('✅ Workflow execution created successfully');
        return {
          'success': true,
          'message': data['message'] ?? 'Workflow created successfully',
          'data': data['data']
        };
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to trigger workflow');
      }
    } catch (e) {
      print('❌ Error triggering workflow execution: $e');
      return {
        'success': false,
        'message': e.toString()
      };
    }
  }

  /// Get requisition with workflow details
  Future<Map<String, dynamic>> getRequisitionWithWorkflow(int requisitionId) async {
    try {
      print('🔍 Loading requisition with workflow: $requisitionId');
      
      // ✅ EXACTLY like workflow_api_service.dart
      final response = await http.get(
        Uri.parse('$baseUrl/requisition/$requisitionId/with-approvers/'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'success' && data['data'] != null) {
          print('✅ Requisition with workflow loaded');
          return {
            'status': 'success',
            'data': data['data']
          };
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to load requisition: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading requisition with workflow: $e');
      rethrow;
    }
  }
}
