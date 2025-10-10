import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html; // ✅ For web navigation (same tab)
import '../providers/workflow_provider.dart';
import '../models/workflow_template.dart';
import '../widgets/workflow_canvas.dart';
import '../widgets/dialogs/node_edit_dialog.dart';

class WorkflowCreationScreen extends StatefulWidget {
  final int? templateId;
  final String mode; // 'create', 'edit', 'view'

  const WorkflowCreationScreen({
    super.key,
    this.templateId,
    this.mode = 'create',
  });

  @override
  State<WorkflowCreationScreen> createState() => _WorkflowCreationScreenState();
}

class _WorkflowCreationScreenState extends State<WorkflowCreationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ScrollController _canvasScrollController = ScrollController();

  // ✅ NEW: Available departments list
  List<Department> _availableDepartments = [];
  bool _loadingDepartments = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeWorkflow();
    });
  }

  Future<void> _initializeWorkflow() async {
    final provider = Provider.of<WorkflowProvider>(context, listen: false);
    
    // Step 1: Initialize workflow data (stages, nodes, employees)
    await provider.initialize();
    
    // Step 2: Load departments
    await _loadDepartments();
    
    // Step 3: ✅ Load existing template if in edit/view mode
    if (widget.templateId != null && (widget.mode == 'edit' || widget.mode == 'view')) {
      print('📥 Initializing in ${widget.mode} mode with template ID: ${widget.templateId}');
      await provider.loadTemplate(widget.templateId!);
    }
    
    // Step 4: Update text controllers with loaded data
    _nameController.text = provider.template.name;
    _descriptionController.text = provider.template.description;
  }

  // ✅ NEW: Load departments from API - EXACTLY like React
  Future<void> _loadDepartments() async {
    setState(() {
      _loadingDepartments = true;
    });

    try {
      // React code reference (Line 269-282):
      // const deptResponse = await axios.get(`${ApiURL}reference-data/?reference_type=9`);
      // const departmentsList = deptResponse.data.results?.map((dept) => ({
      //   id: dept.id,
      //   name: dept.reference_value,
      //   code: dept.reference_code || dept.reference_value,
      // })) || [];
      
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/reference-data/?reference_type=9'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Parse the 'results' array from response
        final results = data['results'] as List<dynamic>?;
        
        if (results != null && results.isNotEmpty) {
          _availableDepartments = results.map((dept) {
            return Department(
              id: dept['id'] as int,
              name: dept['reference_value'] as String,
            );
          }).toList();
          
          print('✅ Loaded ${_availableDepartments.length} departments from API');
          print('   Departments: ${_availableDepartments.map((d) => d.name).join(", ")}');
        } else {
          print('⚠️ No departments found in API response');
          _availableDepartments = [];
        }
      } else {
        print('❌ Failed to load departments: HTTP ${response.statusCode}');
        _availableDepartments = [];
      }
    } catch (e) {
      print('❌ Error loading departments: $e');
      print('   Make sure the API is running at http://127.0.0.1:8000');
      _availableDepartments = [];
    } finally {
      setState(() {
        _loadingDepartments = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Consumer<WorkflowProvider>(
        builder: (context, provider, child) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Header
              _buildHeader(provider),
              
              // Error banner
              if (provider.error != null) _buildErrorBanner(provider),
              
              // ✅ FIX: Connection mode banner - persists until Cancel clicked
              if (provider.connectionMode) _buildConnectionBanner(provider),
              
              // Main content
              Expanded(
                child: Row(
                  children: [
                    // Left sidebar
                    _buildLeftSidebar(provider),
                    
                    // Canvas area
                    Expanded(
                      child: _buildCanvasArea(provider),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(WorkflowProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.mode == 'create'
                      ? 'Create Workflow Template'
                      : widget.mode == 'edit'
                          ? 'Edit Workflow Template'
                          : 'View Workflow Template',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                // ✅ Show template ID in edit/view mode
                if (widget.templateId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Template ID: ${widget.templateId}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (widget.mode != 'view') ...[
            ElevatedButton.icon(
              onPressed: provider.saving ? null : () => _saveTemplate(provider),
              // ✅ Different icon for edit mode
              icon: Icon(
                provider.saving
                    ? Icons.hourglass_empty
                    : widget.mode == 'edit'
                        ? Icons.edit
                        : Icons.save,
              ),
              // ✅ Different text for edit mode
              label: Text(
                provider.saving
                    ? widget.mode == 'edit'
                        ? 'Updating...'
                        : 'Saving...'
                    : widget.mode == 'edit'
                        ? 'Update Template'
                        : 'Save Template',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
            const SizedBox(width: 12),
          ],
          OutlinedButton(
            onPressed: () => _handleCancel(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
            child: Text(widget.mode == 'view' ? 'Close' : 'Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(WorkflowProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.red.shade100,
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              provider.error!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => provider.clearError(),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionBanner(WorkflowProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.blue.shade100,
      child: Row(
        children: [
          const Icon(Icons.link, color: Colors.blue),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Connection Mode: Click on a target node to create connection. Click Cancel or press ESC to exit.',
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            onPressed: () => provider.cancelConnection(),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue,
            ),
            child: const Text('Cancel Connection'),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftSidebar(WorkflowProvider provider) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Template Information
            const Text(
              'Template Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Name field
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Template Name *',
                border: OutlineInputBorder(),
                hintText: 'e.g., Standard Requisition Approval',
              ),
              onChanged: (value) => provider.updateTemplateInfo(name: value),
              enabled: widget.mode != 'view',
            ),
            const SizedBox(height: 16),
            
            // Description field
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                hintText: 'Describe this workflow template',
              ),
              maxLines: 3,
              onChanged: (value) => provider.updateTemplateInfo(description: value),
              enabled: widget.mode != 'view',
            ),
            const SizedBox(height: 16),
            
            // Stage dropdown
            DropdownButtonFormField<int>(
              initialValue: provider.selectedStage?.id,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Workflow Stage *',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: provider.availableStages.map((stage) {
                return DropdownMenuItem<int>(
                  value: stage.id,
                  child: Text(
                    stage.description,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              }).toList(),
              onChanged: widget.mode == 'view'
                  ? null
                  : (stageId) async {
                      if (stageId != null) {
                        final stage = provider.availableStages.firstWhere(
                          (s) => s.id == stageId,
                        );
                        
                        if (provider.template.nodes.isNotEmpty) {
                          final confirm = await _showStageChangeWarning();
                          if (confirm == true) {
                            await provider.changeStage(stage);
                          }
                        } else {
                          await provider.changeStage(stage);
                        }
                      }
                    },
            ),
            const SizedBox(height: 16),
            
            // ✅ NEW: Department dropdown
            if (_loadingDepartments)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              DropdownButtonFormField<int>(
                value: provider.template.department,
                isExpanded: true, // ✅ FIX: Prevent overflow
                decoration: const InputDecoration(
                  labelText: 'Department',
                  border: OutlineInputBorder(),
                  hintText: 'Optional',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text(
                      '-- Global --',
                      overflow: TextOverflow.ellipsis, // ✅ FIX: Handle long text
                      maxLines: 1,
                    ),
                  ),
                  ..._availableDepartments.map((dept) {
                    return DropdownMenuItem<int>(
                      value: dept.id,
                      child: Text(
                        dept.name,
                        overflow: TextOverflow.ellipsis, // ✅ FIX: Handle long text
                        maxLines: 1,
                      ),
                    );
                  }).toList(),
                ],
                onChanged: widget.mode == 'view'
                    ? null
                    : (value) {
                        provider.updateTemplateInfo(department: value);
                      },
              ),
            const SizedBox(height: 24),
            
            // Node Palette
            if (widget.mode != 'view') _buildNodePalette(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildNodePalette(WorkflowProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available Nodes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Click to add nodes to the workflow',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        
        if (provider.stageConstraints.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No nodes available for this stage',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ...provider.stageConstraints.map((constraint) {
            final existingCount = provider.template.nodes
                .where((n) => n.data.dbNodeId == constraint.node.id)
                .length;
            final canAdd = existingCount < constraint.maxCount;
            
            // ✅ FIX: Filter out required nodes (min=1, max=1) from palette
            if (constraint.minCount == 1 && constraint.maxCount == 1) {
              return const SizedBox.shrink();
            }
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: canAdd
                    ? () => provider.addNode(constraint.node)
                    : null,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: canAdd ? Colors.blue.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: canAdd ? Colors.blue.shade200 : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        constraint.node.type == 'Stop'
                            ? Icons.stop_circle
                            : Icons.check_circle,
                        color: canAdd ? Colors.blue : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              constraint.node.displayName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: canAdd ? Colors.black : Colors.grey,
                              ),
                            ),
                            Text(
                              '$existingCount/${constraint.maxCount} added',
                              style: TextStyle(
                                fontSize: 12,
                                color: canAdd ? Colors.grey.shade600 : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        canAdd ? Icons.add : Icons.block,
                        color: canAdd ? Colors.blue : Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildCanvasArea(WorkflowProvider provider) {
    return Container(
      color: Colors.grey[100],
      child: SingleChildScrollView(
        controller: _canvasScrollController,
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: WorkflowCanvas(
            nodes: provider.template.nodes,
            edges: provider.template.edges,
            onNodeDrag: (nodeId, position) {
              provider.updateNodePosition(nodeId, position);
            },
            onNodeTap: (nodeId) {
              if (widget.mode != 'view') {
                final node = provider.template.nodes.firstWhere((n) => n.id == nodeId);
                // Only show edit dialog for approval nodes, not outcome nodes
                if (node.type == 'approval') {
                  provider.selectNode(nodeId);
                  _showNodeEditDialog(provider, nodeId);
                }
              }
            },
            connectionMode: provider.connectionMode,
            connectionSource: provider.connectionSource,
            onStartConnection: (nodeId) {
              provider.startConnection(nodeId);
            },
            onCompleteConnection: (nodeId) {
              provider.completeConnection(nodeId);
            },
            onCancelConnection: () {
              provider.cancelConnection();
            },
            onDeleteEdge: (edgeId) {
              provider.deleteEdge(edgeId);
            },
            readonly: widget.mode == 'view',
          ),
        ),
      ),
    );
  }

  // ✅ Handle cancel button - Navigate to Django templates page (same tab)
  void _handleCancel() {
    // React code: window.location.href = 'http://127.0.0.1:8000/workflow/templates/';
    // Flutter web: Use dart:html for same-tab navigation
    html.window.location.href = 'http://127.0.0.1:8000/workflow/templates/';
  }

  // ✅ Handle save template - Show success then navigate to templates page
  Future<void> _saveTemplate(WorkflowProvider provider) async {
    final success = await provider.saveTemplate();
    
    if (success) {
      if (!mounted) return;
      
      // ✅ Different message based on mode
      final message = widget.mode == 'edit'
          ? '✅ Workflow template updated successfully!'
          : '✅ Workflow template created successfully!';
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      
      // React code: After save, calls handleClose() → window.location.href
      // Flutter web: Navigate to Django templates page (same tab)
      await Future.delayed(const Duration(milliseconds: 1000)); // Let user see success message
      html.window.location.href = 'http://127.0.0.1:8000/workflow/templates/';
    }
  }

  // ✅ FIX: Stage change warning dialog
  Future<bool?> _showStageChangeWarning() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Change Workflow Stage?'),
          ],
        ),
        content: const Text(
          'You have nodes in your current workflow. Changing the stage will clear all existing nodes and connections.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Clear Workflow'),
          ),
        ],
      ),
    );
  }

  void _showNodeEditDialog(WorkflowProvider provider, String nodeId) {
    final node = provider.template.nodes.firstWhere((n) => n.id == nodeId);
    
    // Only show edit dialog for approval nodes, not outcome nodes
    if (node.type != 'approval') return;

    showDialog(
      context: context,
      builder: (context) => NodeEditDialog(
        node: node,
        nodeId: nodeId,
        availableEmployees: provider.availableEmployees,
        loadingEmployees: provider.loadingEmployees,
        onUpdateNode: (nodeId, newData) {
          provider.updateNodeData(nodeId, newData);
        },
        onDeleteNode: (nodeId) {
          if (!node.data.isRequired) {
            provider.deleteNode(nodeId);
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _canvasScrollController.dispose();
    super.dispose();
  }
}

// ✅ NEW: Department model
class Department {
  final int id;
  final String name;

  Department({required this.id, required this.name});
}
