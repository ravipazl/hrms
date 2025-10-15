import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/template_list_provider.dart';
import '../../models/form_builder/form_template.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart' as custom_error;
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/confirmation_dialog.dart';
import 'form_builder_screen.dart';

/// Form List Screen - Browse and manage form templates
class FormListScreen extends StatefulWidget {
  const FormListScreen({super.key});

  @override
  State<FormListScreen> createState() => _FormListScreenState();
}

class _FormListScreenState extends State<FormListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'date';

  @override
  void initState() {
    super.initState();
    // Load templates on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TemplateListProvider>(context, listen: false).loadTemplates();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TemplateListProvider()..loadTemplates(),
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: _buildAppBar(context),
        body: Consumer<TemplateListProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const LoadingWidget(message: 'Loading templates...');
            }

            if (provider.error != null) {
              return custom_error.ErrorWidget(
                title: 'Failed to Load Templates',
                message: provider.error!,
                onRetry: provider.loadTemplates,
              );
            }

            if (provider.templates.isEmpty) {
              if (provider.searchQuery.isNotEmpty) {
                return EmptyStateWidget(
                  title: 'No Results Found',
                  message: 'No templates match "${provider.searchQuery}"',
                  icon: Icons.search_off,
                  onAction: () {
                    _searchController.clear();
                    provider.searchTemplates('');
                  },
                  actionLabel: 'Clear Search',
                );
              }
              return EmptyStateWidget(
                title: 'No Forms Yet',
                message: 'Create your first form to get started',
                icon: Icons.description_outlined,
                onAction: () => _createNewForm(context),
                actionLabel: 'Create Form',
              );
            }

            return _buildTemplateGrid(context, provider);
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _createNewForm(context),
          icon: const Icon(Icons.add),
          label: const Text('New Form'),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Form Templates'),
      elevation: 0,
      actions: [
        // Refresh Button
        Consumer<TemplateListProvider>(
          builder: (context, provider, _) {
            return IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: provider.isLoading ? null : provider.refresh,
              tooltip: 'Refresh',
            );
          },
        ),

        // Sort Menu
        PopupMenuButton<String>(
          icon: const Icon(Icons.sort),
          tooltip: 'Sort',
          initialValue: _sortBy,
          onSelected: (value) {
            setState(() => _sortBy = value);
            Provider.of<TemplateListProvider>(
              context,
              listen: false,
            ).sortTemplates(value);
          },
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'date',
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 18),
                      SizedBox(width: 8),
                      Text('Last Modified'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'name',
                  child: Row(
                    children: [
                      Icon(Icons.sort_by_alpha, size: 18),
                      SizedBox(width: 8),
                      Text('Name'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'submissions',
                  child: Row(
                    children: [
                      Icon(Icons.assignment_turned_in, size: 18),
                      SizedBox(width: 8),
                      Text('Submissions'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'views',
                  child: Row(
                    children: [
                      Icon(Icons.visibility, size: 18),
                      SizedBox(width: 8),
                      Text('Views'),
                    ],
                  ),
                ),
              ],
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: _buildSearchBar(context),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Consumer<TemplateListProvider>(
      builder: (context, provider, _) {
        return TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search forms...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon:
                provider.searchQuery.isNotEmpty
                    ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        provider.searchTemplates('');
                      },
                    )
                    : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          onChanged: provider.searchTemplates,
        );
      },
    );
  }

  Widget _buildTemplateGrid(
    BuildContext context,
    TemplateListProvider provider,
  ) {
    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 400,
          childAspectRatio: 1.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: provider.templates.length,
        itemBuilder: (context, index) {
          final template = provider.templates[index];
          return _TemplateCard(
            template: template,
            onEdit: () => _editTemplate(context, template.id),
            onDelete: () => _deleteTemplate(context, provider, template),
            onView: () => _viewTemplate(context, template.id),
          );
        },
      ),
    );
  }

  void _createNewForm(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FormBuilderScreen()),
    ).then((_) {
      // Refresh list when returning
      Provider.of<TemplateListProvider>(context, listen: false).refresh();
    });
  }

  void _editTemplate(BuildContext context, String templateId) {
    Navigator.pushNamed(context, '/form-builder/edit?id=$templateId').then((_) {
      Provider.of<TemplateListProvider>(context, listen: false).refresh();
    });
  }

  void _viewTemplate(BuildContext context, String templateId) {
    Navigator.pushNamed(context, '/form-builder/view?id=$templateId');
  }

  Future<void> _deleteTemplate(
    BuildContext context,
    TemplateListProvider provider,
    FormTemplate template,
  ) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Form',
      message:
          'Are you sure you want to delete "${template.title}"? This action cannot be undone.',
      confirmText: 'Delete',
      isDangerous: true,
    );

    if (confirmed == true) {
      final success = await provider.deleteTemplate(template.id);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Form deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: ${provider.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Template Card Widget
class _TemplateCard extends StatelessWidget {
  final FormTemplate template;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onView;

  const _TemplateCard({
    required this.template,
    required this.onEdit,
    required this.onDelete,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with actions
              Row(
                children: [
                  Expanded(
                    child: Text(
                      template.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    itemBuilder:
                        (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 18),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'view',
                            child: Row(
                              children: [
                                Icon(Icons.visibility, size: 18),
                                SizedBox(width: 8),
                                Text('View'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'duplicate',
                            child: Row(
                              children: [
                                Icon(Icons.content_copy, size: 18),
                                SizedBox(width: 8),
                                Text('Duplicate'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit();
                          break;
                        case 'view':
                          onView();
                          break;
                        case 'duplicate':
                          // TODO: Implement duplicate
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Description
              if ((template.description ?? '').isNotEmpty)
                Text(
                  template.description ?? '',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

              const Spacer(),

              // Stats row
              Row(
                children: [
                  _buildStat(
                    Icons.description,
                    '${template.fieldsCount} fields',
                  ),
                  const SizedBox(width: 16),
                  _buildStat(Icons.visibility, '${template.viewCount}'),
                  const SizedBox(width: 16),
                  _buildStat(
                    Icons.assignment_turned_in,
                    '${template.submissionCount}',
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Footer
              Row(
                children: [
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          template.isPublished
                              ? Colors.green[50]
                              : Colors.orange[50],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color:
                            template.isPublished
                                ? Colors.green[300]!
                                : Colors.orange[300]!,
                      ),
                    ),
                    child: Text(
                      template.isPublished ? 'Published' : 'Draft',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color:
                            template.isPublished
                                ? Colors.green[700]
                                : Colors.orange[700],
                      ),
                    ),
                  ),
                  const Spacer(),

                  // Last updated
                  Text(
                    'Updated ${template.formattedUpdatedDate}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }
}
