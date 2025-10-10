import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/form_builder/form_field.dart' as form_models;
import '../../../providers/form_builder_provider.dart';

/// Interactive Field Wrapper - Makes fields clickable, selectable, and draggable for reordering
class InteractiveFieldWrapper extends StatefulWidget {
  final form_models.FormField field;
  final Widget child;
  final int index;

  const InteractiveFieldWrapper({
    super.key,
    required this.field,
    required this.child,
    required this.index,
  });

  @override
  State<InteractiveFieldWrapper> createState() => _InteractiveFieldWrapperState();
}

class _InteractiveFieldWrapperState extends State<InteractiveFieldWrapper> {
  bool _isHovering = false;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<FormBuilderProvider>(
      builder: (context, provider, _) {
        final isSelected = provider.selectedField?.id == widget.field.id;

        return LongPressDraggable<Map<String, dynamic>>(
          data: {
            'field': widget.field,
            'index': widget.index,
          },
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
                        widget.field.type.toShortString(),
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
            child: _buildFieldContent(provider, isSelected, isDragging: true),
          ),
          onDragStarted: () {
            setState(() => _isDragging = true);
            debugPrint('Started dragging field: ${widget.field.label}');
          },
          onDragEnd: (details) {
            setState(() => _isDragging = false);
            debugPrint('Ended dragging field: ${widget.field.label}');
          },
          child: _buildFieldContent(provider, isSelected),
        );
      },
    );
  }

  Widget _buildFieldContent(
    FormBuilderProvider provider,
    bool isSelected, {
    bool isDragging = false,
  }) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: isDragging ? null : () {
          // Select field on click
          provider.selectField(widget.field.id);
        },
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
              // Field content
              Padding(
                padding: isSelected || _isHovering
                    ? const EdgeInsets.only(top: 32)
                    : EdgeInsets.zero,
                child: IgnorePointer(
                  // Prevent field interactions in builder mode
                  child: widget.child,
                ),
              ),

              // Action buttons (shown on hover or selection)
              if (isSelected || _isHovering)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Field type indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.field.type.toShortString(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[900],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Duplicate button
                      _buildActionButton(
                        icon: Icons.content_copy,
                        tooltip: 'Duplicate',
                        onPressed: () {
                          provider.duplicateField(widget.field.id);
                        },
                      ),

                      // Delete button
                      _buildActionButton(
                        icon: Icons.delete_outline,
                        tooltip: 'Delete',
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
                ),

              // Selection indicator badge
              if (isSelected)
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
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
        title: const Text('Delete Field'),
        content: Text(
          'Are you sure you want to delete "${widget.field.label}"?',
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
