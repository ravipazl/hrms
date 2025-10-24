// lib/services/workflow_execution_api_service.dart
// ✅ UPDATED to use Dio with authentication

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dio/browser.dart';
import '../models/workflow_execution/workflow_execution.dart';
import '../models/workflow_template.dart';
import 'auth_service.dart';

class WorkflowExecutionApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  
  final Dio _dio;
  final AuthService _authService;
  
  WorkflowExecutionApiService({AuthService? authService}) 
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
          print('❌ Workflow Execution API Error: ${error.response?.statusCode} - ${error.message}');
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
        logPrint: (obj) => print('🔄 [Execution API] $obj'),
      ),
    );
  }

  /// Get workflow execution status for a requisition (REQUIRES AUTH)
  Future<Map<String, dynamic>> getWorkflowExecutionStatus(int requisitionId) async {
    try {
      print('🔍 Loading workflow execution status for requisition: $requisitionId');
      
      final response = await _dio.get(
        '/api/workflow/requisition/$requisitionId/execution-status/',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
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

  /// Get available workflow templates (REQUIRES AUTH)
  Future<List<WorkflowTemplate>> getAvailableTemplates({int? departmentId}) async {
    try {
      print('📋 Loading workflow templates...');
      
      final queryParams = <String, dynamic>{};
      if (departmentId != null) {
        queryParams['department'] = departmentId;
        print('🏢 Filtering by department ID: $departmentId');
      }
      
      final response = await _dio.get(
        '/api/workflow/templates/',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        print('📝 Raw API Response type: ${data.runtimeType}');
        if (data is Map) {
          print('📝 Response keys: ${(data as Map).keys.toList()}');
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
        
        print('✅ Loaded ${templates.length} workflow templates');
        return templates;
      } else {
        throw Exception('Failed to load templates: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading workflow templates: $e');
      return [];
    }
  }

  /// Update requisition status (REQUIRES AUTH)
  Future<Map<String, dynamic>> updateRequisitionStatus(int requisitionId, String status) async {
    try {
      print('📝 Updating requisition $requisitionId status to: $status');
      
      final response = await _dio.patch(
        '/api/requisition/$requisitionId/',
        data: {'status': status},
      );

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;
        print('✅ Status updated successfully');
        return {
          'success': true,
          'message': 'Status updated to $status successfully',
          'status': data['status'] ?? status
        };
      } else {
        final errorData = response.data;
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

  /// Trigger workflow execution (REQUIRES AUTH)
  Future<Map<String, dynamic>> triggerWorkflowExecution({
    required int requisitionId,
    required int workflowTemplateId,
  }) async {
    try {
      print('🚀 Triggering workflow execution');
      print('   - Requisition ID: $requisitionId');
      print('   - Template ID: $workflowTemplateId');
      
      final response = await _dio.post(
        '/api/workflow/trigger-execution/',
        data: {
          'requisition_id': requisitionId,
          'workflow_template_id': workflowTemplateId,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        print('✅ Workflow execution created successfully');
        return {
          'success': true,
          'message': data['message'] ?? 'Workflow created successfully',
          'data': data['data']
        };
      } else {
        final errorData = response.data;
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

  /// Get requisition with workflow details (REQUIRES AUTH)
  Future<Map<String, dynamic>> getRequisitionWithWorkflow(int requisitionId) async {
    try {
      print('🔍 Loading requisition with workflow: $requisitionId');
      
      final response = await _dio.get(
        '/api/requisition/$requisitionId/with-approvers/',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
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
