import 'package:flutter/material.dart';
import '../../models/workflow_node.dart';

class NodeEditDialog extends StatefulWidget {
  final WorkflowNode node;
  final String nodeId;
  final List<Employee> availableEmployees;
  final bool loadingEmployees;
  final Function(String nodeId, WorkflowNodeData newData) onUpdateNode;
  final Function(String nodeId) onDeleteNode;

  const NodeEditDialog({
    Key? key,
    required this.node,
    required this.nodeId,
    required this.availableEmployees,
    required this.loadingEmployees,
    required this.onUpdateNode,
    required this.onDeleteNode,
  }) : super(key: key);

  @override
  State<NodeEditDialog> createState() => _NodeEditDialogState();
}

class _NodeEditDialogState extends State<NodeEditDialog> {
  late TextEditingController _titleController;
  late TextEditingController _userIdController;
  late TextEditingController _commentController;
  int? _selectedEmployeeId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.node.data.title ?? widget.node.data.label,
    );
    _userIdController = TextEditingController(
      text: widget.node.data.userId ?? '',
    );
    _commentController = TextEditingController(
      text: widget.node.data.comment ?? '',
    );
    _selectedEmployeeId = widget?.node?.data?.selectedEmployeeId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _userIdController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  String _getNodeTypeTitle() {
    switch (widget.node.type) {
      case 'approval':
        return 'Approval Step';
      case 'interview':
        return 'Interview Process';
      case 'panelist':
        return 'Interview Panelist';
      default:
        return 'Workflow Node';
    }
  }

  void _handleEmployeeChange(String? employeeId) {
    if (employeeId == null || employeeId.isEmpty) return;

    final selectedEmployee = widget.availableEmployees.firstWhere(
      (emp) => emp.id.toString() == employeeId,
      orElse: () => Employee(
        id: 0,
        fullName: '',
        username: '',
        userId: '',
        email: '',
        isActive: false,
      ),
    );

    if (selectedEmployee.id != 0) {
      setState(() {
        _selectedEmployeeId = selectedEmployee.id;
        _userIdController.text = selectedEmployee.userId;
      });

      // Update node data
      final newData = widget.node.data.copyWith(
        selectedEmployeeId: selectedEmployee.id,
        username: selectedEmployee.username,
        userId: selectedEmployee.userId,
        employeeName: selectedEmployee.fullName,
        employeeEmail: selectedEmployee.email,
        employeePhone: selectedEmployee.phone,
        badgeId: selectedEmployee.badgeId,
      );

      widget.onUpdateNode(widget.nodeId, newData);
    }
  }

  void _handleTitleChange(String value) {
    final newData = widget.node.data.copyWith(
      title: value,
      label: value,
    );
    widget.onUpdateNode(widget.nodeId, newData);
  }

  void _handleUserIdChange(String value) {
    final newData = widget.node.data.copyWith(userId: value);
    widget.onUpdateNode(widget.nodeId, newData);
  }

  void _handleCommentChange(String value) {
    final newData = widget.node.data.copyWith(comment: value);
    widget.onUpdateNode(widget.nodeId, newData);
  }

  void _handleDelete() {
    widget.onDeleteNode(widget.nodeId);
    Navigator.of(context).pop();
  }

  void _handleSaveAndClose() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  const Text('⚙️', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Text(
                    'Edit ${_getNodeTypeTitle()}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title field
                    _buildTextField(
                      label: 'Title *',
                      controller: _titleController,
                      onChanged: _handleTitleChange,
                      placeholder: 'e.g., Department Head Approval',
                    ),
                    const SizedBox(height: 16),

                    // Username dropdown
                    _buildEmployeeDropdown(),
                    const SizedBox(height: 16),

                    // User ID field
                    _buildTextField(
                      label: 'User ID *',
                      controller: _userIdController,
                      onChanged: _handleUserIdChange,
                      placeholder: 'e.g., dept_head',
                    ),
                    const SizedBox(height: 16),

                    // Comment field
                    _buildTextField(
                      label: 'Comment Text',
                      controller: _commentController,
                      onChanged: _handleCommentChange,
                      placeholder: 'Add description or instructions for this step...',
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),

            // Footer buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  // Delete button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _handleDelete,
                      icon: const Text('🗑️'),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Save & Close button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _handleSaveAndClose,
                      icon: const Text('💾'),
                      label: const Text('Save & Close'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required Function(String) onChanged,
    String? placeholder,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: onChanged,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: placeholder,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Username *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        widget.loadingEmployees
            ? Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Loading employees...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            : DropdownButtonFormField<String>(
                value: _selectedEmployeeId?.toString(),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                hint: const Text('Select Employee...'),
                items: widget.availableEmployees
                    .where((emp) => emp.isActive)
                    .map((emp) => DropdownMenuItem<String>(
                          value: emp.id.toString(),
                          child: Text('${emp.fullName} (${emp.username})'),
                        ))
                    .toList(),
                onChanged: _handleEmployeeChange,
              ),
      ],
    );
  }
}

// Employee model class
class Employee {
  final int id;
  final String fullName;
  final String username;
  final String userId;
  final String email;
  final String? phone;
  final String? badgeId;
  final bool isActive;

  Employee({
    required this.id,
    required this.fullName,
    required this.username,
    required this.userId,
    required this.email,
    this.phone,
    this.badgeId,
    required this.isActive,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      fullName: json['full_name'] ?? '',
      username: json['username'] ?? '',
      userId: json['user_id']?.toString() ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      badgeId: json['badge_id'],
      isActive: json['is_active'] ?? true,
    );
  }
}
