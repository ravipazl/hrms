import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeWorkflow();
    });
  }

  Future<void> _initializeWorkflow() async {
    final provider = Provider.of<WorkflowProvider>(context, listen: false);
    
    await provider.initialize();
    
    if (widget.templateId != null && widget.mode == 'edit') {
      await provider.loadTemplate(widget.templateId!);
    }
    
    _nameController.text = provider.template.name;
    _descriptionController.text = provider.template.description;
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
              
              // Connection mode banner
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
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (widget.mode != 'view') ...[
            ElevatedButton.icon(
              onPressed: provider.saving ? null : () => _saveTemplate(provider),
              icon: Icon(provider.saving ? Icons.hourglass_empty : Icons.save),
              label: Text(provider.saving ? 'Saving...' : 'Save Template'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
            const SizedBox(width: 12),
          ],
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
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
              'Connection Mode: Click on a target node to create connection',
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            onPressed: () => provider.cancelConnection(),
            child: const Text('Cancel'),
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
            DropdownButtonFormField<WorkflowStage>(
              value: provider.selectedStage,
              decoration: const InputDecoration(
                labelText: 'Workflow Stage *',
                border: OutlineInputBorder(),
              ),
              items: provider.availableStages.map((stage) {
                return DropdownMenuItem(
                  value: stage,
                  child: Text(stage.description),
                );
              }).toList(),
              onChanged: widget.mode == 'view'
                  ? null
                  : (stage) async {
                      if (stage != null) {
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
          'Drag nodes to the canvas or click to add',
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
                provider.selectNode(nodeId);
                _showNodeEditDialog(provider, nodeId);
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

  Future<void> _saveTemplate(WorkflowProvider provider) async {
    final success = await provider.saveTemplate();
    
    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Template saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    }
  }

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
