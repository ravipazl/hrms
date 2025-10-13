// lib/services/workflow_approval_api_service.dart

import 'dart:convert';
import 'dart:ui';
import 'package:http/http.dart' as http;
import '../models/approval/workflow_step_detail.dart';

class WorkflowApprovalApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  /// Get workflow step details for approval
  Future<WorkflowStepDetail> getWorkflowStep(int stepId) async {
    try {
      print('🔍 Loading workflow step: $stepId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/workflow/workflow-steps/$stepId/'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
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

  /// Get available outcomes from workflow edges
  Future<List<ActionOutcome>> getAvailableOutcomes(int templateId, int currentNodeId) async {
    try {
      print('🔍 Loading available outcomes for template: $templateId, node: $currentNodeId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/workflow/workflow-edges/?template=$templateId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
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

        // Map to ActionOutcome objects
        if (uniqueOutcomes.isNotEmpty) {
          return uniqueOutcomes.map((outcome) {
            return _mapOutcomeToAction(outcome);
          }).toList();
        } else {
          // Return default outcomes
          print('⚠️ No outcomes found in edges, using defaults');
          return _getDefaultOutcomes();
        }
      } else {
        print('⚠️ Failed to load edges: ${response.statusCode}');
        return _getDefaultOutcomes();
      }
    } catch (e) {
      print('❌ Error loading available outcomes: $e');
      return _getDefaultOutcomes();
    }
  }

  /// Map outcome string to ActionOutcome object with color and icon
  ActionOutcome _mapOutcomeToAction(String outcome) {
    final normalized = outcome.toLowerCase();
    
    switch (normalized) {
      case 'approved':
      case 'approve':
        return ActionOutcome(
          value: normalized,
          label: _capitalize(normalized),
          color: const Color(0xFF10B981), // green
          icon: '✓',
        );
      case 'rejected':
      case 'reject':
        return ActionOutcome(
          value: normalized,
          label: _capitalize(normalized),
          color: const Color(0xFFEF4444), // red
          icon: '✗',
        );
      case 'hold':
        return ActionOutcome(
          value: normalized,
          label: _capitalize(normalized),
          color: const Color(0xFFF59E0B), // orange
          icon: '⏸',
        );
      case 'escalate':
        return ActionOutcome(
          value: normalized,
          label: _capitalize(normalized),
          color: const Color(0xFF8B5CF6), // purple
          icon: '⬆️',
        );
      case 'forward':
        return ActionOutcome(
          value: normalized,
          label: _capitalize(normalized),
          color: const Color(0xFF3B82F6), // blue
          icon: '➡️',
        );
      case 'verify':
        return ActionOutcome(
          value: normalized,
          label: _capitalize(normalized),
          color: const Color(0xFF06B6D4), // cyan
          icon: '🔍',
        );
      case 'review':
        return ActionOutcome(
          value: normalized,
          label: _capitalize(normalized),
          color: const Color(0xFFF97316), // orange
          icon: '📝',
        );
      default:
        return ActionOutcome(
          value: normalized,
          label: _capitalize(normalized),
          color: const Color(0xFF3B82F6), // default blue
          icon: '❓',
        );
    }
  }

  /// Get default outcomes as fallback
  List<ActionOutcome> _getDefaultOutcomes() {
    return [
      ActionOutcome(
        value: 'approved',
        label: 'Approved',
        color: const Color(0xFF10B981),
        icon: '✓',
      ),
      ActionOutcome(
        value: 'hold',
        label: 'Hold',
        color: const Color(0xFFF59E0B),
        icon: '⏸',
      ),
      ActionOutcome(
        value: 'rejected',
        label: 'Rejected',
        color: const Color(0xFFEF4444),
        icon: '✗',
      ),
    ];
  }

  /// Capitalize first letter
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Submit approval action
  Future<Map<String, dynamic>> updateStepStatus({
    required int stepId,
    required String outcome,
    required String comments,
    List<Map<String, dynamic>>? approvedPositions,
  }) async {
    try {
      print('🚀 Submitting approval action');
      print('   - Step ID: $stepId');
      print('   - Outcome: $outcome');
      print('   - Comments: ${comments.substring(0, comments.length > 50 ? 50 : comments.length)}...');
      if (approvedPositions != null) {
        print('   - Approved positions: ${approvedPositions.length}');
      }

      final Map<String, dynamic> body = {
        'outcome': outcome,
        'comments': comments,
      };

      // Add approved_positions only if provided and not empty
      if (approvedPositions != null && approvedPositions.isNotEmpty) {
        body['approved_positions'] = approvedPositions;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/workflow/workflow-steps/$stepId/update_status/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Approval submitted successfully');
        return {
          'success': true,
          'status': data['status'],
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to submit approval');
      }
    } catch (e) {
      print('❌ Error submitting approval: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
}
