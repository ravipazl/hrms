import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:hrms/widgets/dialogs/node_edit_dialog.dart';
import '../models/workflow_template.dart';
import '../models/workflow_node.dart';
import '../models/workflow_edge.dart';
import '../services/workflow_api_service.dart';
import '../services/employee_api_service.dart';

class WorkflowProvider with ChangeNotifier {
  final WorkflowApiService _apiService = WorkflowApiService();
  final EmployeeApiService _employeeApiService = EmployeeApiService();
  
  // ✅ FIX: Counters to ensure unique IDs
  static int _nodeIdCounter = 0;
  static int _edgeIdCounter = 0;

  // Template data
  WorkflowTemplate _template = WorkflowTemplate(
    name: '',
    description: '',
    stage: '',
    nodes: [],
    edges: [],
  );

  // Available data from database
  List<WorkflowStage> _availableStages = [];
  List<DatabaseNode> _availableNodeTypes = [];
  List<StageNodeConstraint> _stageConstraints = [];

  // UI state
  bool _loading = false;
  bool _saving = false;
  String? _error;
  WorkflowStage? _selectedStage;
  String? _selectedNodeId;
  bool _connectionMode = false;
  String? _connectionSource;
  
  // Employee data
  List<Employee> _availableEmployees = [];
  bool _loadingEmployees = false;

  // NEW: Required nodes tracking
  bool _requiredNodesAdded = false;

  // Getters
  WorkflowTemplate get template => _template;
  List<WorkflowStage> get availableStages => _availableStages;
  List<DatabaseNode> get availableNodeTypes => _availableNodeTypes;
  List<StageNodeConstraint> get stageConstraints => _stageConstraints;
  bool get loading => _loading;
  bool get saving => _saving;
  String? get error => _error;
  WorkflowStage? get selectedStage => _selectedStage;
  String? get selectedNodeId => _selectedNodeId;
  bool get connectionMode => _connectionMode;
  String? get connectionSource => _connectionSource;
  List<Employee> get availableEmployees => _availableEmployees;
  bool get loadingEmployees => _loadingEmployees;

  /// Initialize workflow data
  Future<void> initialize() async {
    _loading = true;
    notifyListeners();

    try {
      // Load stages
      _availableStages = await _apiService.loadStages();
      
      // Load node types
      _availableNodeTypes = await _apiService.loadAvailableNodes();
      
      // Load employees
      await loadEmployees();

      // Set default stage if available
      if (_availableStages.isNotEmpty && _selectedStage == null) {
        _selectedStage = _availableStages.first;
        _template = _template.copyWith(
          stage: _selectedStage!.name,
          selectedStage: _selectedStage,
        );
        
        // Load constraints for default stage
        await loadStageConstraints(_selectedStage!.id);
      }

      _error = null;
    } catch (e) {
      _error = 'Failed to initialize: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Load employees from API
  Future<void> loadEmployees() async {
    _loadingEmployees = true;
    notifyListeners();
    
    try {
      _availableEmployees = await _employeeApiService.loadEmployees();
      print('Loaded ${_availableEmployees.length} employees');
    } catch (e) {
      print('Failed to load employees: $e');
      _availableEmployees = [];
    } finally {
      _loadingEmployees = false;
      notifyListeners();
    }
  }

  /// Load template by ID
  Future<void> loadTemplate(int templateId) async {
    _loading = true;
    notifyListeners();

    try {
      print('📥 Loading template with ID: $templateId');
      
      // Load template from API
      _template = await _apiService.loadWorkflowTemplate(templateId);
      _selectedStage = _template.selectedStage;
      
      print('✅ Template loaded: ${_template.name}');
      print('   - Nodes: ${_template.nodes.length}');
      print('   - Edges: ${_template.edges.length}');
      print('   - Stage: ${_selectedStage?.name}');
      print('   - Department: ${_template.department}');
      
      // Load stage constraints for this stage
      if (_selectedStage != null) {
        await loadStageConstraints(_selectedStage!.id);
      }
      
      // Mark required nodes as already added (loaded from DB)
      _requiredNodesAdded = true;
      _error = null;
    } catch (e) {
      print('❌ Failed to load template: $e');
      _error = 'Failed to load template: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Load stage constraints
  Future<void> loadStageConstraints(int stageId) async {
    try {
      _stageConstraints = await _apiService.loadStageNodes(stageId);
      
      // ✅ FIX: Auto-add required nodes only if not already added
      if (!_requiredNodesAdded) {
        _autoAddRequiredNodes();
        _requiredNodesAdded = true;
      }
      
      notifyListeners();
    } catch (e) {
      print('Failed to load stage constraints: $e');
    }
  }

  /// ✅ FIX: Auto-add required nodes (min_count = 1, max_count = 1)
  void _autoAddRequiredNodes() {
    final requiredConstraints = _stageConstraints
        .where((c) => c.minCount == 1 && c.maxCount == 1)
        .toList();

    for (var constraint in requiredConstraints) {
      final exists = _template.nodes.any(
        (node) => node.data.dbNodeId == constraint.node.id,
      );

      if (!exists) {
        addNode(constraint.node, isRequired: true);
      }
    }
  }

  /// Update template info
  void updateTemplateInfo({
    String? name,
    String? description,
    int? department,
    bool? isGlobalDefault,
  }) {
    _template = _template.copyWith(
      name: name ?? _template.name,
      description: description ?? _template.description,
      department: department ?? _template.department,
      isGlobalDefault: isGlobalDefault ?? _template.isGlobalDefault,
    );
    notifyListeners();
  }

  /// ✅ FIX: Change workflow stage with proper cleanup
  Future<void> changeStage(WorkflowStage stage) async {
    if (stage.id == _selectedStage?.id) return;

    // Clear workflow data and reset required nodes flag
    _template = _template.copyWith(
      stage: stage.name,
      selectedStage: stage,
      nodes: [],
      edges: [],
    );
    
    _selectedStage = stage;
    _requiredNodesAdded = false; // Reset flag for new stage
    
    await loadStageConstraints(stage.id);
    notifyListeners();
  }

  /// Add node to workflow
  void addNode(DatabaseNode dbNode, {bool isRequired = false}) {
    // Check max count
    final constraint = _stageConstraints.firstWhere(
      (c) => c.node.id == dbNode.id,
      orElse: () => StageNodeConstraint(
        id: 0,
        stage: 0,
        node: dbNode,
        minCount: 0,
        maxCount: 1,
        stageName: '',
        nodeName: '',
        nodeType: '',
      ),
    );

    final existingCount = _template.nodes
        .where((n) => n.data.dbNodeId == dbNode.id)
        .length;

    if (existingCount >= constraint.maxCount) {
      _error = 'Cannot add more ${dbNode.displayName} nodes. Maximum ${constraint.maxCount} allowed.';
      notifyListeners();
      return;
    }

    // Determine position - Better positioning logic
    final isOutcomeNode = dbNode.type == 'Stop';
    
    // Calculate position based on existing nodes of same type
    final sameTypeNodes = _template.nodes.where((n) => 
      (isOutcomeNode && n.type == 'outcome') || 
      (!isOutcomeNode && n.type != 'outcome')
    ).toList();
    
    final baseX = 200.0 + (sameTypeNodes.length * 250.0); // More spacing
    final baseY = isOutcomeNode ? 480.0 : 200.0; // Outcome nodes lower

    // Determine UI node type
    final uiNodeType = dbNode.type == 'Stop' ? 'outcome' : 'approval';
    
    // ✅ DATABASE-DRIVEN: Get outcome type from display_name
    String? outcomeType;
    if (dbNode.type == 'Stop') {
      // Use display_name from database API
      outcomeType = _getOutcomeTypeFromDisplayName(dbNode.displayName);
      
      // ✅ DEBUG: Log the outcome assignment
      print('🎯 Creating outcome node:');
      print('   - dbNode.id: ${dbNode.id}');
      print('   - dbNode.name: ${dbNode.name}');
      print('   - dbNode.displayName: ${dbNode.displayName}');
      print('   - Assigned outcome: $outcomeType');
    }

    // Get color
    final color = uiNodeType == 'outcome'
        ? _getColorForOutcome(outcomeType ?? 'default')
        : const Color(0xFF3B82F6);

    // Create new node with guaranteed unique ID
    _nodeIdCounter++;
    final newNode = WorkflowNode(
      id: '$uiNodeType-${DateTime.now().millisecondsSinceEpoch}-$_nodeIdCounter',
      type: uiNodeType,
      position: Offset(baseX, baseY),
      data: WorkflowNodeData(
        label: '${dbNode.displayName} ${existingCount + 1}',
        title: '${dbNode.displayName} ${existingCount + 1}',
        color: color,
        stepOrder: existingCount + 1,
        dbNodeId: dbNode.id,
        nodeType: dbNode.name,
        username: 'user',
        userId: 'user',
        comment: '${dbNode.displayName} step',
        outcome: outcomeType,
        isRequired: isRequired,
      ),
    );

    print('✅ Node created with outcome: ${newNode.data.outcome}');

    final updatedNodes = List<WorkflowNode>.from(_template.nodes)..add(newNode);
    _template = _template.copyWith(nodes: updatedNodes);
    _error = null;
    notifyListeners();
  }

  /// Update node position - FIXED: Better error handling and debugging
  void updateNodePosition(String nodeId, Offset newPosition) {
    print('📍 updateNodePosition called');
    print('   - nodeId: $nodeId');
    print('   - newPosition: $newPosition');
    print('   - Total nodes in template: ${_template.nodes.length}');
    
    // ✅ CRITICAL FIX: Check if node exists BEFORE updating
    final nodeIndex = _template.nodes.indexWhere((n) => n.id == nodeId);
    
    if (nodeIndex == -1) {
      print('   ❌ ERROR: Node $nodeId NOT FOUND in template!');
      print('   - Available node IDs:');
      for (var node in _template.nodes) {
        print('     * ${node.id} (${node.data.label})');
      }
      // ⚠️ DON'T call notifyListeners() if node not found!
      return;
    }
    
    final node = _template.nodes[nodeIndex];
    print('   ✅ Found node: ${node.data.label}');
    print('   - Old position: ${node.position}');
    print('   - New position: $newPosition');
    
    // Create updated nodes list with modified position
    final updatedNodes = List<WorkflowNode>.from(_template.nodes);
    updatedNodes[nodeIndex] = node.copyWith(position: newPosition);
    
    // Update template
    _template = _template.copyWith(nodes: updatedNodes);
    
    print('   ✅ Position updated successfully');
    notifyListeners();
  }

  /// Update node data
  void updateNodeData(String nodeId, WorkflowNodeData newData) {
    final updatedNodes = _template.nodes.map((node) {
      if (node.id == nodeId) {
        return node.copyWith(data: newData);
      }
      return node;
    }).toList();

    _template = _template.copyWith(nodes: updatedNodes);
    notifyListeners();
  }

  /// Delete node
  void deleteNode(String nodeId) {
    final updatedNodes = _template.nodes.where((n) => n.id != nodeId).toList();
    final updatedEdges = _template.edges
        .where((e) => e.source != nodeId && e.target != nodeId)
        .toList();

    _template = _template.copyWith(
      nodes: updatedNodes,
      edges: updatedEdges,
    );
    notifyListeners();
  }

  /// Start connection mode
  void startConnection(String sourceNodeId) {
    _connectionMode = true;
    _connectionSource = sourceNodeId;
    notifyListeners();
  }

  /// ✅ FIX: Complete connection with correct label and clear source
  void completeConnection(String targetNodeId) {
    print('🔗 completeConnection called');
    print('   - targetNodeId: $targetNodeId');
    print('   - _connectionMode: $_connectionMode');
    print('   - _connectionSource: $_connectionSource');
    
    if (!_connectionMode || _connectionSource == null) return;
    
    // Don't connect to self
    if (_connectionSource == targetNodeId) {
      print('   ⚠️ Trying to connect to self, ignoring');
      return;
    }

    // Check if this specific connection already exists
    final exists = _template.edges.any(
      (e) => e.source == _connectionSource && e.target == targetNodeId,
    );

    if (exists) {
      print('   ⚠️ Connection already exists');
      notifyListeners(); // Still notify to update UI
      return;
    }

    // Get target node to determine label
    final targetNode = _template.nodes.firstWhere(
      (n) => n.id == targetNodeId,
      orElse: () => WorkflowNode(
        id: '',
        type: 'approval',
        position: Offset.zero,
        data: WorkflowNodeData(label: '', title: '', color: const Color(0xFF3B82F6)),
      ),
    );
    
    if (targetNode.id.isEmpty) {
      print('   ⚠️ Target node not found!');
      return;
    }
    
    // ✅ DATABASE-DRIVEN: Correct label determination from node data
    String label = 'Proceed';
    String condition = 'approved';
    
    if (targetNode.type == 'outcome' && targetNode.data.outcome != null) {
      // Use the ACTUAL outcome stored in the node (derived from database display_name)
      final outcome = targetNode.data.outcome!;
      label = outcome.toUpperCase(); // APPROVED, HOLD, REJECTED
      condition = outcome.toLowerCase(); // approved, hold, rejected
      
      print('   🎯 Creating edge to outcome node:');
      print('      - Target outcome: $outcome');
      print('      - Edge label: $label');
      print('      - Edge condition: $condition');
    } else if (targetNode.type == 'approval') {
      // For Process nodes, use "Proceed to" prefix
      label = 'Proceed to ${targetNode.data.label}';
      condition = 'approved';
    }

    // Create edge with guaranteed unique ID
    _edgeIdCounter++;
    final newEdge = WorkflowEdge(
      id: 'edge-${DateTime.now().millisecondsSinceEpoch}-$_edgeIdCounter',
      source: _connectionSource!,
      target: targetNodeId,
      label: label,
      type: 'straight',
      data: {'condition': condition},
    );

    final updatedEdges = List<WorkflowEdge>.from(_template.edges)..add(newEdge);
    _template = _template.copyWith(edges: updatedEdges);
    
    print('   ✅ Connection created: $_connectionSource -> $targetNodeId');
    print('   ✅ Edge label: $label, condition: $condition');
    print('   ✅ Total edges now: ${updatedEdges.length}');

    // ✅ CRITICAL FIX: Clear connection source but keep mode active
    // This removes the dashed preview line while keeping connection mode on
    // User must click connection handle again to start new connection
    _connectionSource = null;
    print('   🔄 Connection mode stays ACTIVE, but source cleared');
    print('   🔄 Dashed preview line will disappear');
    print('   🔄 User must click connection handle again for next connection');
    
    notifyListeners();
  }

  /// Cancel connection
  void cancelConnection() {
    _connectionMode = false;
    _connectionSource = null;
    notifyListeners();
  }

  /// Delete edge
  void deleteEdge(String edgeId) {
    final updatedEdges = _template.edges.where((e) => e.id != edgeId).toList();
    _template = _template.copyWith(edges: updatedEdges);
    notifyListeners();
  }

  /// Select node
  void selectNode(String? nodeId) {
    _selectedNodeId = nodeId;
    notifyListeners();
  }

  /// Save template
  Future<bool> saveTemplate() async {
    // Validate
    if (_template.name.isEmpty) {
      _error = 'Template name is required';
      notifyListeners();
      return false;
    }

    if (_template.description.isEmpty) {
      _error = 'Description is required';
      notifyListeners();
      return false;
    }

    if (_selectedStage == null) {
      _error = 'Workflow stage must be selected';
      notifyListeners();
      return false;
    }

    _saving = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.saveWorkflowTemplate(_template);
      
      // Update template with saved ID
      if (_template.id == null && result['id'] != null) {
        _template = _template.copyWith(id: result['id']);
      }

      _saving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to save template: $e';
      _saving = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// ✅ DATABASE-DRIVEN: Convert display_name to outcome type
  String _getOutcomeTypeFromDisplayName(String displayName) {
    final normalized = displayName.toLowerCase().trim();
    
    // Handle common variations
    if (normalized == 'approved' || normalized == 'approve') {
      return 'approved';
    } else if (normalized == 'hold' || normalized == 'on hold') {
      return 'hold';
    } else if (normalized == 'reject' || normalized == 'rejected') {
      return 'rejected';
    }
    
    // Default: use normalized display_name as-is
    return normalized;
  }

  /// Get color for outcome
  Color _getColorForOutcome(String outcomeType) {
    const colors = {
      'approved': Color(0xFF10B981),
      'hold': Color(0xFFF59E0B),
      'rejected': Color(0xFFEF4444),
      'default': Color(0xFF6B7280),
    };
    return colors[outcomeType] ?? colors['default']!;
  }
}
