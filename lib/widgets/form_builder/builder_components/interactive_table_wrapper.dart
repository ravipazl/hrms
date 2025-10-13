import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/form_builder/form_field.dart' as form_models;
import '../../../providers/form_builder_provider.dart';

/// Interactive Table Wrapper - Special wrapper for table fields
/// Allows table interactions while still providing field-level actions
class InteractiveTableWrapper extends StatefulWidget {
  final form_models.FormField field;
  final Widget child;
  final int index;

  const InteractiveTableWrapper({
    super.key,
    required this.field,
    required this.child,
    required this.index,
  });

  @override
  State<InteractiveTableWrapper> createState() => _InteractiveTableWrapperState();
}

class _InteractiveTableWrapperState extends State<InteractiveTableWrapper> {
  bool _isHovering = false;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    // Debug: Print when widget rebuilds
    debugPrint('🎨 TableWrapper building: hover=$_isHovering, drag=$_isDragging');
    
    return Consumer<FormBuilderProvider>(
      builder: (context, provider, _) {
        final isSelected = provider.selectedField?.id == widget.field.id;

        return LongPressDraggable<Map<String, dynamic>>(
          data: {
            'field': widget.field,
            'index': widget.index,
          },
          // Only allow dragging from the header area
          dragAnchorStrategy: pointerDragAnchorStrategy,
          feedback: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Opacity(
              opacity: 0.8,
              child: Container(
                width: 300,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue, width: 2),
                ),
                child: Row(
                  children: [
                    Icon(Icons.drag_indicator, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.field.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'table',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: _buildTableContent(provider, isSelected, isDragging: true),
          ),
          onDragStarted: () {
            setState(() => _isDragging = true);
            debugPrint('Started dragging table field: ${widget.field.label}');
          },
          onDragEnd: (details) {
            setState(() => _isDragging = false);
            debugPrint('Ended dragging table field: ${widget.field.label}');
          },
          child: _buildTableContent(provider, isSelected),
        );
      },
    );
  }

  Widget _buildTableContent(
    FormBuilderProvider provider,
    bool isSelected, {
    bool isDragging = false,
  }) {
    return MouseRegion(
      onEnter: (_) {
        debugPrint('🖱️ MOUSE ENTERED table wrapper');
        setState(() => _isHovering = true);
      },
      onExit: (_) {
        debugPrint('🖱️ MOUSE EXITED table wrapper');
        setState(() => _isHovering = false);
      },
      child: GestureDetector(
        onTap: isDragging ? null : () {
          debugPrint('👆 TABLE WRAPPER CLICKED! Selecting field: ${widget.field.id}');
          // Select field on click (but only on the wrapper, not the table itself)
          provider.selectField(widget.field.id);
        },
        behavior: HitTestBehavior.translucent, // Allow clicks to pass through to table
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, right: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? Colors.blue
                  : _isHovering
                      ? Colors.blue.withOpacity(0.3)
                      : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isSelected
                ? Colors.blue.withOpacity(0.05)
                : _isHovering
                    ? Colors.grey[50]
                    : Colors.white,
          ),
          child: Stack(
            children: [
              // Table content (allows interactions)
              Padding(
                padding: isSelected || _isHovering
                    ? const EdgeInsets.only(top: 40)
                    : EdgeInsets.zero,
                child: widget.child, // Table can be interacted with
              ),

              // Action buttons bar at the top
              if (isSelected || _isHovering)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left side - Selection badge and field type
                        Row(
                          children: [
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'SELECTED',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            if (isSelected) const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.table_chart, size: 12, color: Colors.blue[900]),
                                  const SizedBox(width: 4),
                                  Text(
                                    'table',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue[900],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Right side - Action buttons
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Duplicate button
                            _buildActionButton(
                              icon: Icons.content_copy,
                              tooltip: 'Duplicate Table',
                              onPressed: () {
                                provider.duplicateField(widget.field.id);
                              },
                            ),

                            // Delete button
                            _buildActionButton(
                              icon: Icons.delete_outline,
                              tooltip: 'Delete Table',
                              color: Colors.red,
                              onPressed: () {
                                _showDeleteConfirmation(context, provider);
                              },
                            ),

                            // Drag handle (long press to drag)
                            _buildActionButton(
                              icon: Icons.drag_indicator,
                              tooltip: 'Long press to reorder',
                              color: Colors.green[700],
                              onPressed: null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    Color? color,
    VoidCallback? onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 18,
            color: color ?? Colors.grey[700],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    FormBuilderProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Table Field'),
        content: Text(
          'Are you sure you want to delete the table "${widget.field.label}"?\n\nThis will remove the entire table with all its columns and data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteField(widget.field.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Table'),
          ),
        ],
      ),
    );
  }
}
