// lib/services/workflow_approval_api_service.dart
// ✅ UPDATED to use Dio with authentication

import 'dart:convert';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:dio/browser.dart';
import '../models/approval/workflow_step_detail.dart';  // ActionOutcome is here
import 'auth_service.dart';

class WorkflowApprovalApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  
  final Dio _dio;
  final AuthService _authService;
  
  WorkflowApprovalApiService({AuthService? authService}) 
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
          print('❌ Workflow Approval API Error: ${error.response?.statusCode} - ${error.message}');
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
        logPrint: (obj) => print('🔄 [Approval API] $obj'),
      ),
    );
  }

  /// Get workflow step details for approval (REQUIRES AUTH)
  Future<WorkflowStepDetail> getWorkflowStep(int stepId) async {
    try {
      print('🔍 Loading workflow step: $stepId');
      
      final response = await _dio.get('/api/workflow/workflow-steps/$stepId/');

      if (response.statusCode == 200) {
        final data = response.data;
        print('✅ Workflow step loaded successfully');
        return WorkflowStepDetail.fromJson(data);
      } else {
        throw Exception('Failed to load workflow step: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading workflow step: $e');
      rethrow;
    }
  }

  /// Get available outcomes from workflow edges (REQUIRES AUTH)
  Future<List<ActionOutcome>> getAvailableOutcomes(int templateId, int currentNodeId) async {
    try {
      print('🔍 Loading available outcomes for template: $templateId, node: $currentNodeId');
      
      final response = await _dio.get(
        '/api/workflow/workflow-edges/',
        queryParameters: {'template': templateId},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        // Extract edges list
        List<dynamic> edges;
        if (data is List) {
          edges = data;
        } else if (data['results'] != null) {
          edges = data['results'];
        } else if (data['data'] != null) {
          edges = data['data'];
        } else {
          edges = [];
        }

        // Filter edges from current node
        final nodeEdges = edges.where((edge) => 
          edge['start_node_instance'] == currentNodeId
        ).toList();

        print('🔗 Found ${nodeEdges.length} edges from current node');

        // Extract unique outcomes
        final uniqueOutcomes = <String>{};
        for (var edge in nodeEdges) {
          if (edge['outcome'] != null) {
            uniqueOutcomes.add(edge['outcome'].toString().toLowerCase());
          }
        }

        print('✅ Available outcomes: $uniqueOutcomes');

        // Map to ActionOutcome objects from the model
        if (uniqueOutcomes.isNotEmpty) {
          return uniqueOutcomes.map((outcome) {
            return _mapOutcomeToAction(outcome);
          }).toList();
        } else {
          // Return default outcomes
          return _getDefaultOutcomes();
        }
      } else {
        throw Exception('Failed to load outcomes: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading outcomes: $e');
      return _getDefaultOutcomes();
    }
  }
  
  /// Helper: Map outcome string to ActionOutcome
  ActionOutcome _mapOutcomeToAction(String outcome) {
    switch (outcome.toLowerCase()) {
      case 'approved':
        return ActionOutcome(
          value: 'approved',
          label: 'Approve',
          color: const Color(0xFF10B981), // Green
          icon: '✓',
        );
      case 'rejected':
        return ActionOutcome(
          value: 'rejected',
          label: 'Reject',
          color: const Color(0xFFEF4444), // Red
          icon: '✗',
        );
      case 'hold':
        return ActionOutcome(
          value: 'hold',
          label: 'Hold',
          color: const Color(0xFFF59E0B), // Orange
          icon: '⏸',
        );
      default:
        return ActionOutcome(
          value: outcome,
          label: outcome[0].toUpperCase() + outcome.substring(1),
          color: const Color(0xFF6B7280), // Gray
          icon: '•',
        );
    }
  }
  
  /// Helper: Get default outcomes
  List<ActionOutcome> _getDefaultOutcomes() {
    return [
      ActionOutcome(
        value: 'approved',
        label: 'Approve',
        color: const Color(0xFF10B981),
        icon: '✓',
      ),
      ActionOutcome(
        value: 'rejected',
        label: 'Reject',
        color: const Color(0xFFEF4444),
        icon: '✗',
      ),
      ActionOutcome(
        value: 'hold',
        label: 'Hold',
        color: const Color(0xFFF59E0B),
        icon: '⏸',
      ),
    ];
  }

  /// Submit workflow approval decision (REQUIRES AUTH)
  Future<Map<String, dynamic>> submitApproval({
    required int stepId,
    required String outcome,
    required String comments,
    List<Map<String, dynamic>>? approvedPositions,
  }) async {
    try {
      print('📝 Submitting approval for step: $stepId');
      print('   Outcome: $outcome');
      print('   Comments: $comments');
      if (approvedPositions != null) {
        print('   Approved positions: ${approvedPositions.length}');
      }

      final payload = <String, dynamic>{
        'outcome': outcome.toLowerCase(),
        'comments': comments,
      };
      
      if (approvedPositions != null && approvedPositions.isNotEmpty) {
        payload['approved_positions'] = approvedPositions;
      }

      final response = await _dio.post(
        '/api/workflow/workflow-steps/$stepId/update_status/',
        data: payload,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        print('✅ Approval submitted successfully');
        print('   Activated ${data['data']?['activated_count'] ?? 0} next steps');
        return {
          'success': true,
          'message': data['message'] ?? 'Success',
          'data': data['data'],
        };
      } else {
        throw Exception('Failed to submit approval: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error submitting approval: $e');
      rethrow;
    }
  }
  
  /// Alias for submitApproval (for backwards compatibility)
  Future<Map<String, dynamic>> updateStepStatus({
    required int stepId,
    required String outcome,
    required String comments,
    List<Map<String, dynamic>>? approvedPositions,
  }) async {
    return submitApproval(
      stepId: stepId,
      outcome: outcome,
      comments: comments,
      approvedPositions: approvedPositions,
    );
  }

  /// Get pending approvals for a user (REQUIRES AUTH)
  Future<List<WorkflowStepDetail>> getPendingApprovals(String assignedTo) async {
    try {
      print('📋 Loading pending approvals for: $assignedTo');
      
      final response = await _dio.get(
        '/api/workflow/workflow-steps/pending_approvals/',
        queryParameters: {'assigned_to': assignedTo},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        if (data['status'] == 'success' && data['data'] != null) {
          final approvals = data['data']['pending_approvals'] as List;
          print('✅ Found ${approvals.length} pending approvals');
          
          return approvals
              .map((approval) => WorkflowStepDetail.fromJson(approval))
              .toList();
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to load pending approvals: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading pending approvals: $e');
      return [];
    }
  }
}
