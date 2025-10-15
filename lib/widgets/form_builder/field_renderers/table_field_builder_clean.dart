import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:uuid/uuid.dart';
import '../../../models/form_builder/form_field.dart' as form_models;

/// Clean Table Field Renderer for Form Builder Canvas
/// Displays simplified preview in builder mode with horizontal scroll
class TableFieldBuilderClean extends StatelessWidget {
  final form_models.FormField field;

  const TableFieldBuilderClean({
    super.key,
    required this.field,
  });
 
  @override
  Widget build(BuildContext context) {
    // Get configuration
    final columns = _getColumns();
    final rows = _getRows();
    final showRowNumbers = field.props['showRowNumbers'] ?? true;
    final striped = field.props['striped'] ?? true;
    final bordered = field.props['bordered'] ?? true;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with field label
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.table_chart, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    field.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (field.required)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Required',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Table preview (simplified for builder)
          Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info row
                Row(
                  children: [
                    _buildInfoChip(
                      Icons.view_column,
                      '${columns.length} columns',
                      Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      Icons.table_rows,
                      '${rows.length} rows',
                      Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Scrollable table preview with fixed width
                Container(
                  height: 250, // Fixed height
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: _buildScrollableTable(
                      context,
                      columns,
                      rows,
                      showRowNumbers,
                      striped,
                      bordered,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Scroll hint
                Row(
                  children: [
                    Icon(Icons.swap_horiz, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Scroll to see all columns',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Configuration summary
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (field.props['allowAddRows'] == true)
                      _buildFeatureChip('Add Rows', Icons.add, Colors.green),
                    if (field.props['allowDeleteRows'] == true)
                      _buildFeatureChip('Delete Rows', Icons.delete, Colors.red),
                    if (field.props['showSerialNumbers'] == true)
                      _buildFeatureChip('Serial #', Icons.numbers, Colors.blue),
                    if (field.props['exportable'] == true)
                      _buildFeatureChip('Exportable', Icons.download, Colors.orange),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color baseColor) {
    // Get darker shade for text
    final textColor = baseColor == Colors.blue ? Colors.blue[700]! : Colors.green[700]!;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: baseColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String label, IconData icon, Color baseColor) {
    // Get darker shade for text color
    final textColor = baseColor == Colors.green 
        ? Colors.green[700]!
        : baseColor == Colors.red 
            ? Colors.red[700]!
            : baseColor == Colors.blue
                ? Colors.blue[700]!
                : Colors.orange[700]!;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: baseColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: baseColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableTable(
    BuildContext context,
    List<Map<String, dynamic>> columns,
    List<Map<String, dynamic>> rows,
    bool showRowNumbers,
    bool striped,
    bool bordered,
  ) {
    // Show all rows in builder preview
    final displayRows = rows.isEmpty 
        ? [{'id': 'row_1', 'data': {}}] 
        : rows;

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        scrollbars: true,
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.stylus,
        },
      ),
      child: Scrollbar(
        thumbVisibility: true,
        trackVisibility: true,
        interactive: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Scrollbar(
            thumbVisibility: true,
            trackVisibility: true,
            interactive: true,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const AlwaysScrollableScrollPhysics(),
              child: DataTable(
                border: bordered
                    ? TableBorder.all(color: Colors.grey[300]!, width: 1)
                    : null,
                headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
                headingRowHeight: 40,
                dataRowHeight: 40,
                columnSpacing: 12,
                horizontalMargin: 8,
                columns: [
                  // Row number column
                  if (showRowNumbers)
                    const DataColumn(
                      label: SizedBox(
                        width: 30,
                        child: Text(
                          '#',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  // All columns (scrollable)
                  ...columns.map((col) {
                    final icon = _getFieldIcon(col['type']?.toString());
                    return DataColumn(
                      label: SizedBox(
                        width: 120, // Fixed column width
                        child: Row(
                          children: [
                            Text(icon, style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                col['label']?.toString() ?? 'Column',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
                rows: displayRows.asMap().entries.map((entry) {
                  final index = entry.key;
                  return DataRow(
                    color: striped && index % 2 == 1
                        ? WidgetStateProperty.all(Colors.grey[50])
                        : WidgetStateProperty.all(Colors.white),
                    cells: [
                      // Row number cell
                      if (showRowNumbers)
                        DataCell(
                          SizedBox(
                            width: 30,
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[700],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      // Data cells (icons showing field types)
                      ...columns.map((col) {
                        final icon = _getFieldIcon(col['type']?.toString());
                        return DataCell(
                          SizedBox(
                            width: 120,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Text(
                                icon,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getFieldIcon(String? type) {
    switch (type) {
      case 'text': return '📝 Text';
      case 'email': return '📧 Email';
      case 'number': return '🔢 Number';
      case 'textarea': return '📄 Text Area';
      case 'select': return '📋 Select';
      case 'radio': return '⚪ Radio';
      case 'checkbox': return '☑️ Checkbox';
      case 'date': return '📅 Date';
      case 'time': return '🕐 Time';
      case 'tel': return '📞 Phone';
      case 'url': return '🌐 URL';
      default: return '📝 Text';
    }
  }

  List<Map<String, dynamic>> _getColumns() {
    final columnsList = field.props['columns'];
    if (columnsList is List) {
      return columnsList.map((e) {
        if (e is Map) {
          final result = <String, dynamic>{};
          e.forEach((key, value) {
            result[key.toString()] = value;
          });
          return result;
        }
        return <String, dynamic>{};
      }).toList();
    }
    return [];
  }

  List<Map<String, dynamic>> _getRows() {
    final rowsList = field.props['rows'];
    if (rowsList is List && rowsList.isNotEmpty) {
      return rowsList.map((e) {
        if (e is Map) {
          return <String, dynamic>{
            'id': e['id']?.toString() ?? const Uuid().v4(),
            'data': e['data'] ?? {},
          };
        }
        return <String, dynamic>{};
      }).toList();
    }
    return [{'id': 'row_1', 'data': {}}];
  }
}
