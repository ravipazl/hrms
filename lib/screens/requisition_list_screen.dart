// lib/screens/requisition_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/requisition_provider.dart';
import '../models/requisition/requisition.dart';
import 'requisition_form_screen.dart';

class RequisitionListScreen extends StatefulWidget {
  const RequisitionListScreen({Key? key}) : super(key: key);

  @override
  State<RequisitionListScreen> createState() => _RequisitionListScreenState();
}

class _RequisitionListScreenState extends State<RequisitionListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RequisitionProvider>(context, listen: false).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Requisition Management'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshData(),
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToForm(),
            tooltip: 'Create New Requisition',
          ),
        ],
      ),
      body: Consumer<RequisitionProvider>(
        builder: (context, provider, child) {
          if (provider.loading && provider.requisitions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Header section
              _buildHeader(provider),
              
              // Error banner
              if (provider.error != null) _buildErrorBanner(provider),
              
              // Filters section
              _buildFilters(provider),
              
              // Results summary
              _buildResultsSummary(provider),
              
              // Requisitions list
              Expanded(
                child: provider.requisitions.isEmpty
                    ? _buildEmptyState(provider)
                    : _buildRequisitionsList(provider),
              ),
              
              // Pagination
              if (provider.totalPages > 1) _buildPagination(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(RequisitionProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Requisition List',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'View and manage all requisition requests',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _navigateToForm(),
            icon: const Icon(Icons.add),
            label: const Text('New Requisition'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(RequisitionProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.red[50],
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

  Widget _buildFilters(RequisitionProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              // Search field
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search by ID, position, department...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (value) => provider.setSearchQuery(value),
                ),
              ),
              const SizedBox(width: 16),
              
              // Department filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: provider.selectedDepartment,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Departments'),
                    ),
                    ...provider.departments.map((dept) => DropdownMenuItem(
                      value: dept.id.toString(),
                      child: Text(dept.referenceValue),
                    )),
                  ],
                  onChanged: (value) => provider.setDepartmentFilter(value),
                ),
              ),
              const SizedBox(width: 16),
              
              // Status filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: provider.selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: null,
                      child: Text('All Status'),
                    ),
                    DropdownMenuItem(
                      value: 'pending',
                      child: Text('Pending'),
                    ),
                    DropdownMenuItem(
                      value: 'in_progress',
                      child: Text('In Progress'),
                    ),
                    DropdownMenuItem(
                      value: 'approved',
                      child: Text('Approved'),
                    ),
                    DropdownMenuItem(
                      value: 'rejected',
                      child: Text('Rejected'),
                    ),
                    DropdownMenuItem(
                      value: 'hold',
                      child: Text('On Hold'),
                    ),
                  ],
                  onChanged: (value) => provider.setStatusFilter(value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  await provider.loadRequisitions(refresh: true);
                },
                icon: provider.loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                label: Text(provider.loading ? 'Searching...' : 'Search'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  provider.clearFilters();
                  provider.loadRequisitions(refresh: true);
                },
                icon: const Icon(Icons.clear),
                label: const Text('Clear Filters'),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => _testApiConnection(provider),
                icon: const Icon(Icons.wifi),
                label: const Text('Test API'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSummary(RequisitionProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey[100],
      child: Row(
        children: [
          Text(
            provider.requisitions.isNotEmpty
                ? 'Showing ${provider.requisitions.length} of ${provider.totalCount} requisitions'
                : 'No requisitions found',
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          if (provider.totalPages > 1) ...[
            const Spacer(),
            Text(
              'Page ${provider.currentPage} of ${provider.totalPages}',
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(RequisitionProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.description_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Requisitions Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            provider.searchQuery.isNotEmpty ||
                    provider.selectedDepartment != null ||
                    provider.selectedStatus != null
                ? 'No requisitions match your current filters.\nTry adjusting the search criteria.'
                : 'No requisitions found in the database.\nCreate your first requisition to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (provider.searchQuery.isNotEmpty ||
                  provider.selectedDepartment != null ||
                  provider.selectedStatus != null)
                OutlinedButton(
                  onPressed: () {
                    _searchController.clear();
                    provider.clearFilters();
                    provider.loadRequisitions(refresh: true);
                  },
                  child: const Text('Clear Filters'),
                ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _navigateToForm(),
                icon: const Icon(Icons.add),
                label: const Text('Create Requisition'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequisitionsList(RequisitionProvider provider) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width - 32,
          ),
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
            columns: const [
              DataColumn(label: Text('Requisition ID')),
              DataColumn(label: Text('Position')),
              DataColumn(label: Text('Department')),
              DataColumn(label: Text('Quantity')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Created At')),
              DataColumn(label: Text('Actions')),
            ],
            rows: provider.requisitions.map((requisition) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      requisition.requisitionId ?? 'REQ-${requisition.id}',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  DataCell(Text(requisition.jobPosition)),
                  DataCell(Text(provider.getDepartmentName(requisition.department))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        requisition.positions
                            .fold<int>(0, (sum, pos) => sum + pos.requisitionQuantity)
                            .toString(),
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  DataCell(_buildStatusBadge(requisition.status)),
                  DataCell(
                    Text(
                      requisition.createdAt != null
                          ? _formatDate(requisition.createdAt!)
                          : 'N/A',
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility, size: 20),
                          onPressed: () => _viewRequisition(requisition),
                          tooltip: 'View',
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _editRequisition(requisition),
                          tooltip: 'Edit',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                          onPressed: () => _deleteRequisition(provider, requisition),
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    String displayText = RequisitionStatus.getDisplayText(status);

    switch (status.toLowerCase()) {
      case 'approved':
        backgroundColor = Colors.green[50]!;
        textColor = Colors.green[700]!;
        break;
      case 'pending':
        backgroundColor = Colors.orange[50]!;
        textColor = Colors.orange[700]!;
        break;
      case 'rejected':
        backgroundColor = Colors.red[50]!;
        textColor = Colors.red[700]!;
        break;
      case 'in_progress':
        backgroundColor = Colors.blue[50]!;
        textColor = Colors.blue[700]!;
        break;
      case 'hold':
        backgroundColor = Colors.grey[50]!;
        textColor = Colors.grey[700]!;
        break;
      default:
        backgroundColor = Colors.grey[50]!;
        textColor = Colors.grey[700]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildPagination(RequisitionProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: provider.currentPage > 1
                ? () {
                    provider.previousPage();
                    provider.loadRequisitions();
                  }
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          const SizedBox(width: 16),
          Text(
            'Page ${provider.currentPage} of ${provider.totalPages}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: provider.currentPage < provider.totalPages
                ? () {
                    provider.nextPage();
                    provider.loadRequisitions();
                  }
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  // Helper methods
  void _refreshData() {
    Provider.of<RequisitionProvider>(context, listen: false)
        .loadRequisitions(refresh: true);
  }

  void _navigateToForm([Requisition? requisition]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RequisitionFormScreen(
          requisition: requisition,
        ),
      ),
    ).then((_) => _refreshData());
  }

  void _viewRequisition(Requisition requisition) {
    _showRequisitionDetails(requisition);
  }

  void _editRequisition(Requisition requisition) {
    _navigateToForm(requisition);
  }

  Future<void> _deleteRequisition(RequisitionProvider provider, Requisition requisition) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Requisition'),
        content: Text(
          'Are you sure you want to delete requisition "${requisition.requisitionId ?? 'REQ-${requisition.id}'}"?\n\n'
          'Position: ${requisition.jobPosition}\n'
          'Department: ${provider.getDepartmentName(requisition.department)}\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && requisition.id != null) {
      final success = await provider.deleteRequisition(requisition.id!);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Requisition deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _showRequisitionDetails(Requisition requisition) {
    final provider = Provider.of<RequisitionProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Requisition Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('ID', requisition.requisitionId ?? 'REQ-${requisition.id}'),
              _buildDetailRow('Position', requisition.jobPosition),
              _buildDetailRow('Department', provider.getDepartmentName(requisition.department)),
              _buildDetailRow('Qualification', requisition.qualification),
              _buildDetailRow('Experience', requisition.experience),
              _buildDetailRow('Essential Skills', requisition.essentialSkills),
              if (requisition.desiredSkills?.isNotEmpty == true)
                _buildDetailRow('Desired Skills', requisition.desiredSkills!),
              _buildDetailRow('Status', RequisitionStatus.getDisplayText(requisition.status)),
              if (requisition.createdAt != null)
                _buildDetailRow('Created At', _formatDate(requisition.createdAt!)),
              if (requisition.jobDescription?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                const Text('Job Description:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(requisition.jobDescription!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _editRequisition(requisition);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _testApiConnection(RequisitionProvider provider) async {
    final success = await provider.testApiConnection();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'API connection successful!'
                : 'API connection failed. Please check backend server.',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
