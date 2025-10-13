import 'package:flutter/material.dart';

/// Drag and Drop Helper Methods for Dynamic Table
/// Add these methods to _DynamicTableFieldRendererState class

// ==================== COLUMN REORDERING ====================

/// Reorder column from oldIndex to newIndex
void reorderColumn(
  List<Map<String, dynamic>> columns,
  int oldIndex,
  int newIndex,
  Function() updateFieldData,
  Function(VoidCallback) setState,
) {
  if (oldIndex == newIndex) return;
  
  setState(() {
    debugPrint('📊 Reordering column from $oldIndex to $newIndex');
    
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    final column = columns.removeAt(oldIndex);
    columns.insert(newIndex, column);
    
    updateFieldData();
  });
}

/// Build draggable column header
Widget buildDraggableColumnHeader({
  required Map<String, dynamic> column,
  required int columnIndex,
  required bool allowDeleteColumns,
  required bool isBuilder,
  required bool allowReorder,
  required String? draggedColumnId,
  required Function(String?) setDraggedColumnId,
  required Widget Function(Map<String, dynamic>, bool, double) buildHeaderContent,
  required double columnWidth,
}) {
  if (!isBuilder || !allowReorder) {
    return buildHeaderContent(column, allowDeleteColumns, columnWidth);
  }

  return Draggable<Map<String, dynamic>>(
    data: {
      'type': 'column',
      'columnId': column['id'],
      'columnIndex': columnIndex,
    },
    feedback: Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          border: Border.all(color: Colors.blue, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.drag_indicator, color: Colors.blue[700], size: 16),
            const SizedBox(width: 8),
            Text(
              column['name'].toString(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    ),
    childWhenDragging: Opacity(
      opacity: 0.3,
      child: buildHeaderContent(column, allowDeleteColumns, columnWidth),
    ),
    onDragStarted: () {
      setDraggedColumnId(column['id']);
      debugPrint('🎯 Started dragging column: ${column['name']}');
    },
    onDragEnd: (details) {
      setDraggedColumnId(null);
      debugPrint('🎯 Ended dragging column: ${column['name']}');
    },
    child: buildHeaderContent(column, allowDeleteColumns, columnWidth),
  );
}

/// Build column drop target
Widget buildColumnDropTarget({
  required bool isHovered,
  required Function(Map<String, dynamic>) onAccept,
}) {
  return AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    width: isHovered ? 40 : 4,
    height: 60,
    decoration: BoxDecoration(
      color: isHovered ? Colors.blue[100] : Colors.transparent,
      borderRadius: BorderRadius.circular(4),
    ),
    child: isHovered
        ? Icon(Icons.add_circle, color: Colors.blue[700], size: 20)
        : null,
  );
}

// ==================== ROW REORDERING ====================

/// Reorder row from oldIndex to newIndex
void reorderRow(
  List<Map<String, dynamic>> rows,
  int oldIndex,
  int newIndex,
  Function() updateFieldData,
  Function(VoidCallback) setState,
) {
  if (oldIndex == newIndex) return;
  
  setState(() {
    debugPrint('📊 Reordering row from $oldIndex to $newIndex');
    
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    final row = rows.removeAt(oldIndex);
    rows.insert(newIndex, row);
    
    updateFieldData();
  });
}

/// Build draggable row number cell
Widget buildDraggableRowCell({
  required int index,
  required String rowId,
  required bool isBuilder,
  required bool allowReorder,
  required String? draggedRowId,
  required Function(String?) setDraggedRowId,
}) {
  if (!isBuilder || !allowReorder) {
    return SizedBox(
      width: 60,
      child: Row(
        children: [
          Icon(Icons.drag_indicator, size: 16, color: Colors.grey.shade400),
          const SizedBox(width: 4),
          Text('${index + 1}'),
        ],
      ),
    );
  }

  return Draggable<Map<String, dynamic>>(
    data: {
      'type': 'row',
      'rowIndex': index,
    },
    feedback: Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green[50],
          border: Border.all(color: Colors.green, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.drag_indicator, color: Colors.green[700], size: 16),
            const SizedBox(width: 8),
            Text(
              'Row ${index + 1}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    ),
    childWhenDragging: Opacity(
      opacity: 0.3,
      child: SizedBox(
        width: 60,
        child: Row(
          children: [
            Icon(Icons.drag_indicator, size: 16, color: Colors.grey.shade400),
            const SizedBox(width: 4),
            Text('${index + 1}'),
          ],
        ),
      ),
    ),
    onDragStarted: () {
      setDraggedRowId(rowId);
      debugPrint('🎯 Started dragging row ${index + 1}');
    },
    onDragEnd: (details) {
      setDraggedRowId(null);
      debugPrint('🎯 Ended dragging row ${index + 1}');
    },
    child: SizedBox(
      width: 60,
      child: Row(
        children: [
          Icon(
            Icons.drag_indicator,
            size: 16,
            color: draggedRowId == rowId ? Colors.green : Colors.grey.shade400,
          ),
          const SizedBox(width: 4),
          Text('${index + 1}'),
        ],
      ),
    ),
  );
}

/// Build row drop target
DataRow buildRowDropTarget({
  required bool isHovered,
  required int columnsCount,
}) {
  return DataRow(
    cells: [
      DataCell(
        Container(
          height: isHovered ? 40 : 4,
          color: isHovered ? Colors.green[100] : Colors.transparent,
          child: isHovered
              ? Center(child: Icon(Icons.add_circle, color: Colors.green[700]))
              : null,
        ),
      ),
      ...List.generate(
        columnsCount,
        (_) => const DataCell(SizedBox()),
      ),
    ],
  );
}
