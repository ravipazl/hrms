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
    Key? key,
    this.templateId,
    this.mode = 'create',
  }) : super(key: key);

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
                // if (widget.templateId != null)
                //   Padding(
                //     padding: const EdgeInsets.only(top: 4),
                //     child: Text(
                //       'Template ID: ${widget.templateId}',
                //       style: TextStyle(
                //         fontSize: 12,
                //         color: Colors.grey.shade600,
                //       ),
                //     ),
                //   ),
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
            child: Text(widget.mode == 'view' ? 'Close' : 'Cancel'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
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
        padding: const EdgeInsets.only(top: 10, left: 24, right: 24, bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Template Name field
            const Text(
              'Template Name *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                hintText: 'e.g., Standard Requisition Approval',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) => provider.updateTemplateInfo(name: value),
              enabled: widget.mode != 'view',
            ),
            const SizedBox(height: 20),
            
            // Description field
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                hintText: 'Describe this requisition approval workflow template',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 3,
              onChanged: (value) => provider.updateTemplateInfo(description: value),
              enabled: widget.mode != 'view',
            ),
            const SizedBox(height: 20),
            
            // Workflow Stage dropdown
            const Text(
              'Workflow Stage *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: provider.selectedStage?.id,
              isExpanded: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                filled: true,
                fillColor: Colors.white,
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
            const SizedBox(height: 20),
            
            // Department dropdown
            const Text(
              'Department',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
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
                isExpanded: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                  hintText: '-- Select Department --',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: [
                  DropdownMenuItem<int>(
                    value: null,
                    child: Text(
                      '-- Select Department --',
                      style: TextStyle(color: Colors.grey.shade600),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  ..._availableDepartments.map((dept) {
                    return DropdownMenuItem<int>(
                      value: dept.id,
                      child: Text(
                        dept.name,
                        overflow: TextOverflow.ellipsis,
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
            const SizedBox(height: 32),
            
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
        Text(
          'Add Workflow Step - ${provider.selectedStage?.description ?? "Requisition"}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
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
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canAdd
                      ? () => provider.addNode(constraint.node)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canAdd ? const Color(0xFF2563EB) : Colors.grey.shade300,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade600,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        constraint.node.displayName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '$existingCount/${constraint.maxCount}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
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
