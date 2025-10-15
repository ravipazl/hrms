import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/form_builder_provider.dart';
import '../../../models/form_builder/form_field.dart' as form_models;
import '../header/form_header_preview.dart';
import 'canvas_field_renderer.dart';
 
class InteractiveFormCanvas extends StatelessWidget {
  const InteractiveFormCanvas({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FormBuilderProvider>(
      builder: (context, provider, _) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Preview
                FormHeaderPreview(
                  formTitle: provider.formTitle,
                  formDescription: provider.formDescription,
                  headerConfig: provider.headerConfig,
                  mode: 'builder',
                ),
                
                // Spacing after header
                if (provider.headerConfig.enabled)
                  const SizedBox(height: 24),
                
                if (provider.fields.isEmpty)
                  _buildEmptyState()
                else
                  _buildFieldsWithDropZones(provider),
                
                const SizedBox(height: 24),
                _buildBottomDropZone(provider),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build fields with drop zones between them for reordering
  Widget _buildFieldsWithDropZones(FormBuilderProvider provider) {
    final fields = provider.fields;
    final List<Widget> children = [];

    // Add drop zone at the top
    children.add(_buildDropZoneBetweenFields(provider, -1, 'Drop here to add at top'));

    for (int i = 0; i < fields.length; i++) {
      final field = fields[i];
      
      // Add the field
      children.add(
        CanvasFieldRenderer.renderFieldWithIndex(field, i),
      );

      // Add drop zone after each field (except last)
      if (i < fields.length - 1) {
        children.add(_buildDropZoneBetweenFields(provider, i, 'Drop here'));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  /// Build a drop zone between fields for reordering
  Widget _buildDropZoneBetweenFields(
    FormBuilderProvider provider,
    int afterIndex,
    String hintText,
  ) {
    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (details) {
        // Accept if it's a field being reordered
        return details.data.containsKey('field');
      },
      onAcceptWithDetails: (details) {
        final data = details.data;
        final field = data['field'] as form_models.FormField;
        final oldIndex = data['index'] as int;
        final newIndex = afterIndex + 1;

        debugPrint('Reordering: ${field.label} from $oldIndex to $newIndex');

        // Reorder the field
        provider.reorderFields(oldIndex, newIndex);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: isHovered ? 60 : 8,
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isHovered ? Colors.blue[50] : Colors.transparent,
            border: isHovered
                ? Border.all(color: Colors.blue, width: 2, style: BorderStyle.solid)
                : Border.all(color: Colors.transparent, width: 0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: isHovered
              ? Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        hintText,
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              : Container(),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(64),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.drag_indicator, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Drag fields from sidebar to start building',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomDropZone(FormBuilderProvider provider) {
    return DragTarget<Object>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        final data = details.data;
        if (data is form_models.FieldType) {
          // Adding new field from sidebar
          provider.addField(data);
        } else if (data is Map<String, dynamic> && data.containsKey('field')) {
          // Reordering existing field to bottom
          final field = data['field'] as form_models.FormField;
          final oldIndex = data['index'] as int;
          final newIndex = provider.fields.length - 1;
          
          if (oldIndex != newIndex) {
            debugPrint('Moving ${field.label} to bottom');
            provider.reorderFields(oldIndex, newIndex);
          }
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: Border.all(
              color: isHovered ? Colors.blue : Colors.grey[300]!,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isHovered ? Colors.blue[50] : Colors.grey[50],
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isHovered ? Icons.add_circle : Icons.add_circle_outline,
                  color: isHovered ? Colors.blue : Colors.grey[400],
                ),
                const SizedBox(width: 8),
                Text(
                  isHovered ? 'Drop field here' : 'Drop field here to add at bottom',
                  style: TextStyle(
                    color: isHovered ? Colors.blue[700] : Colors.grey[600],
                    fontWeight: isHovered ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
