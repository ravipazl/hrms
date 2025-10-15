import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:html' as html; // For web clipboard and download
import 'dart:async'; // For Timer
import '../../../models/form_builder/form_field.dart' as form_models;
import '../../../providers/form_builder_provider.dart';

/// Unified Dynamic Table Field Renderer
/// Handles both builder and preview modes with clean separation
class DynamicTableFieldRenderer extends StatefulWidget {
  final form_models.FormField field;
  final bool isBuilder;
  final dynamic value;
  final Function(dynamic)? onChanged;

  const DynamicTableFieldRenderer({
    super.key,
    required this.field,
    this.isBuilder = true,
    this.value,
    this.onChanged,
  });

  @override
  State<DynamicTableFieldRenderer> createState() =>
      _DynamicTableFieldRendererState();
}

class _DynamicTableFieldRendererState extends State<DynamicTableFieldRenderer> {
  late List<Map<String, dynamic>> columns;
  late List<Map<String, dynamic>> rows;
  late List<Map<String, dynamic>> displayData; // For preview mode data
  Map<String, dynamic>? editingColumn;
  bool showColumnTypeSelector = false;
  String? draggedColumnId;
  String? draggedRowId;
  
  // Scroll controllers for scrollbars
  late ScrollController _horizontalScrollController;
  late ScrollController _verticalScrollController;
  
  // Auto-scroll timers
  Timer? _horizontalScrollTimer;
  Timer? _verticalScrollTimer;

  @override
  void initState() {
    super.initState();
    _horizontalScrollController = ScrollController();
    _verticalScrollController = ScrollController();
    _initializeTable();
  }

  @override
  void dispose() {
    _horizontalScrollTimer?.cancel();
    _verticalScrollTimer?.cancel();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DynamicTableFieldRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.field != widget.field ||
        oldWidget.value != widget.value ||
        oldWidget.isBuilder != widget.isBuilder) {
      _initializeTable();
    }
  }

  void _initializeTable() {
    // Initialize columns (same for both modes)
    final columnsList = widget.field.props['columns'];
    if (columnsList is List) {
      columns =
          columnsList.map((e) {
            if (e is Map) {
              final result = <String, dynamic>{};
              e.forEach((key, value) {
                result[key.toString()] = value;
              });
              
              // CRITICAL FIX: Sanitize dropdown options on initialization
              if (['select', 'radio', 'checkboxGroup'].contains(result['type'])) {
                final fieldProps = result['fieldProps'] as Map<String, dynamic>? ?? {};
                fieldProps['options'] = _sanitizeOptions(fieldProps['options']);
                result['fieldProps'] = fieldProps;
              }
              
              return result;
            }
            return <String, dynamic>{};
          }).toList();
    } else {
      columns = _getDefaultColumns();
    }

    if (widget.isBuilder) {
      // Builder mode: Use configuration rows from field props
      final rowsList = widget.field.props['rows'];
      if (rowsList is List && rowsList.isNotEmpty) {
        rows =
            rowsList.map((e) {
              if (e is Map) {
                final data = e['data'];
                final convertedData = <String, dynamic>{};
                if (data is Map) {
                  data.forEach((key, value) {
                    convertedData[key.toString()] = value;
                  });
                }
                return <String, dynamic>{
                  'id': e['id']?.toString() ?? const Uuid().v4(),
                  'data': convertedData,
                };
              }
              return _createEmptyRow();
            }).toList();
      } else {
        rows = [_createEmptyRow()];
      }
      displayData = rows; // In builder mode, display data is same as rows
    } else {
      // ============ PREVIEW MODE (FIXED) ============
      final minRows = widget.field.props['minRows'] ?? 1;
      
      // Priority 1: Use widget.value if provided (actual form data being filled)
      if (widget.value is List && (widget.value as List).isNotEmpty) {
        displayData =
            (widget.value as List).map((row) {
              if (row is Map) {
                return <String, dynamic>{
                  'id': row['id']?.toString() ?? const Uuid().v4(),
                  'data': row['data'] ?? <String, dynamic>{},
                };
              }
              return _createEmptyRow();
            }).toList();
        debugPrint('✅ Preview Mode: Loaded ${displayData.length} rows from widget.value');
      } 
      // 🆕 Priority 2: Fallback to configured rows from builder (THIS IS THE FIX!)
      else {
        final configuredRows = widget.field.props['rows'];
        
        if (configuredRows is List && configuredRows.isNotEmpty) {
          // Use the rows that were configured in builder mode
          displayData =
              configuredRows.map((e) {
                if (e is Map) {
                  final data = e['data'];
                  final convertedData = <String, dynamic>{};
                  if (data is Map) {
                    data.forEach((key, value) {
                      convertedData[key.toString()] = value;
                    });
                  }
                  return <String, dynamic>{
                    'id': e['id']?.toString() ?? const Uuid().v4(),
                    'data': convertedData,
                  };
                }
                return _createEmptyRow();
              }).toList();
          debugPrint('✅ Preview Mode: Loaded ${displayData.length} rows from field.props["rows"]');
        } else {
          // Priority 3: Last resort - generate empty rows based on minRows
          displayData = List.generate(minRows, (index) => _createEmptyRow());
          debugPrint('⚠️ Preview Mode: Generated ${displayData.length} empty rows (minRows fallback)');
        }
      }
      
      rows = displayData; // Sync rows with displayData for consistency
    }
  }

  List<Map<String, dynamic>> _getDefaultColumns() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return [
      {
        'id': 'col_${now}_1',
        'name': 'Text Column',
        'type': 'text',
        'label': 'Text Column',
        'required': false,
        'width': 'auto',
        'fieldProps': {'placeholder': 'Enter text...'},
      },
      {
        'id': 'col_${now}_2',
        'name': 'Number Column',
        'type': 'number',
        'label': 'Number Column',
        'required': false,
        'width': 'auto',
        'fieldProps': {'placeholder': 'Enter number...', 'min': 0, 'max': 1000},
      },
    ];
  }

  Map<String, dynamic> _createEmptyRow() {
    return {
      'id':
          'row_${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4().substring(0, 8)}',
      'data': <String, dynamic>{},
    };
  }

  void _updateFieldData() {
    if (!widget.isBuilder) return; // Only update field data in builder mode

    final provider = Provider.of<FormBuilderProvider>(context, listen: false);
    provider.updateField(widget.field.id, {'columns': columns, 'rows': rows});
  }

  void _updatePreviewData() {
    if (widget.isBuilder || widget.onChanged == null) {
      return; // Only update value in preview mode
    }

    widget.onChanged!(displayData);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Builder mode controls - only show in builder mode
          if (widget.isBuilder) ...[
            _buildHeaderControls(),
            if (showColumnTypeSelector) _buildColumnTypeSelector(),
            if (editingColumn != null) _buildColumnSettingsEditor(),
          ],

          // Table Container - different behavior for builder vs preview
          _buildTableContainer(),

          // Footer Info - different content for builder vs preview
          _buildFooterInfo(),
        ],
      ),
    );
  }

  Widget _buildHeaderControls() {
    final allowAddColumns = widget.field.props['allowAddColumns'] ?? true;
    final allowAddRows = widget.field.props['allowAddRows'] ?? true;
    final exportable = widget.field.props['exportable'] ?? true;
    final maxRows = widget.field.props['maxRows'] ?? 50;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.field.label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${columns.length} columns • ${rows.length} rows',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Add Column Button
              ElevatedButton.icon(
                onPressed:
                    allowAddColumns
                        ? () {
                          setState(() {
                            showColumnTypeSelector = true;
                          });
                        }
                        : null,
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Add Column'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Add Row Button
              OutlinedButton.icon(
                onPressed:
                    allowAddRows && rows.length < maxRows ? _addRow : null,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Row'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const Spacer(),

              // Export Button
              if (exportable)
                IconButton(
                  onPressed: _exportToCSV,
                  icon: const Icon(Icons.download),
                  tooltip: 'Export to CSV',
                  color: Colors.blue.shade600,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColumnTypeSelector() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue.shade600),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Select Field Type',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    showColumnTypeSelector = false;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _getAvailableFieldTypes().map((type) {
                  return _buildFieldTypeChip(type);
                }).toList(),
          ),
        ],
      ),
    );
  }

  List<Map<String, String>> _getAvailableFieldTypes() {
    return [
      {'type': 'text', 'name': 'Text', 'icon': '📝'},
      {'type': 'email', 'name': 'Email', 'icon': '📧'},
      {'type': 'number', 'name': 'Number', 'icon': '🔢'},
      {'type': 'textarea', 'name': 'Textarea', 'icon': '📄'},
      {'type': 'select', 'name': 'Select', 'icon': '📋'},
      {'type': 'radio', 'name': 'Radio', 'icon': '⚪'},
      {'type': 'checkbox', 'name': 'Checkbox', 'icon': '☑️'},
      {'type': 'checkboxGroup', 'name': 'Checkbox Group', 'icon': '☑️'},
      {'type': 'date', 'name': 'Date', 'icon': '📅'},
      {'type': 'time', 'name': 'Time', 'icon': '🕐'},
      {'type': 'tel', 'name': 'Phone', 'icon': '📞'},
      {'type': 'url', 'name': 'URL', 'icon': '🌐'},
    ];
  }

  Widget _buildFieldTypeChip(Map<String, String> type) {
    return InkWell(
      onTap: () => _addColumn(type['type']!),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(type['icon']!, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              type['name']!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.blue.shade900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColumnSettingsEditor() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue.shade600),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ColumnSettingsForm(
        column: editingColumn!,
        onSave: (updatedColumn) {
          setState(() {
            final index = columns.indexWhere(
              (c) => c['id'] == updatedColumn['id'],
            );
            if (index != -1) {
              columns[index] = updatedColumn;
              editingColumn = null;
              _updateFieldData();
            }
          });
        },
        onCancel: () {
          setState(() {
            editingColumn = null;
          });
        },
      ),
    );
  }

  Widget _buildTableContainer() {
    final striped = widget.field.props['striped'] ?? true;
    final bordered = widget.field.props['bordered'] ?? true;
    final compact = widget.field.props['compact'] ?? false;
    final showRowNumbers = widget.field.props['showRowNumbers'] ?? true;
    final showSerialNumbers = widget.field.props['showSerialNumbers'] ?? false;
    final allowDeleteRows = widget.field.props['allowDeleteRows'] ?? true;
    final allowDeleteColumns = widget.field.props['allowDeleteColumns'] ?? true;
    final minRows = widget.field.props['minRows'] ?? 1;

    // DYNAMIC WIDTH CALCULATION
    _calculateDynamicColumnWidths();

    // Calculate dynamic height based on display data and compact mode
    // FIX #1: Apply compact spacing
    final headingRowHeight = compact ? 48.0 : 60.0;
    final dataRowHeight = compact ? 40.0 : 56.0;
    final calculatedHeight =
        headingRowHeight + (displayData.length * dataRowHeight);
    const maxAllowedHeight = 600.0;
    final dynamicHeight =
        calculatedHeight > maxAllowedHeight
            ? maxAllowedHeight
            : calculatedHeight;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: dynamicHeight,
            minHeight: headingRowHeight + (minRows * dataRowHeight),
          ),
          child: Builder(
            builder:
                (context) => ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.trackpad,
                    },
                    scrollbars: true,
                  ),
                  child: Scrollbar(
                    controller: _verticalScrollController,
                    thumbVisibility: true,
                    interactive: true,
                    thickness: 12,
                    radius: const Radius.circular(6),
                    child: SingleChildScrollView(
                      controller: _verticalScrollController,
                      scrollDirection: Axis.vertical,
                      child: Scrollbar(
                        controller: _horizontalScrollController,
                        thumbVisibility: true,
                        interactive: true,
                        thickness: 12,
                        radius: const Radius.circular(6),
                        child: SingleChildScrollView(
                          controller: _horizontalScrollController,
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            border:
                                bordered
                                    ? TableBorder.all(
                                      color: Colors.grey.shade300,
                                    )
                                    : null,
                            headingRowColor: WidgetStateProperty.all(
                              Colors.grey.shade100,
                            ),
                            headingRowHeight: headingRowHeight,
                            dataRowHeight: dataRowHeight,
                            // FIX #1: Apply compact spacing to column spacing and margin
                            columnSpacing: compact ? 8 : 16,
                            horizontalMargin: compact ? 8 : 12,
                            columns: [
                              // Row Controls Column
                              if (widget.isBuilder && showRowNumbers)
                                const DataColumn(
                                  label: SizedBox(
                                    width: 60,
                                    child: Text(
                                      'Row',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),

                              // Serial Numbers Column
                              if (showSerialNumbers)
                                const DataColumn(
                                  label: SizedBox(
                                    width: 60,
                                    child: Text(
                                      'S.No',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),

                              // Dynamic Columns
                              ...columns.map<DataColumn>(
                                (column) => DataColumn(
                                  label: _buildColumnHeader(
                                    column,
                                    allowDeleteColumns,
                                  ),
                                ),
                              ),

                              // Actions Column
                              if (widget.isBuilder && allowDeleteRows)
                                const DataColumn(
                                  label: SizedBox(
                                    width: 100,
                                    child: Text(
                                      'Actions',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                            rows:
                                displayData.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final row = entry.value;
                                  final rowData =
                                      row['data'] as Map<String, dynamic>;

                                  return DataRow(
                                    color:
                                        striped && index.isOdd
                                            ? WidgetStateProperty.all(
                                              Colors.grey.shade50,
                                            )
                                            : null,
                                    cells: [
                                      // Row Number Cell with drag
                                      if (widget.isBuilder && showRowNumbers)
                                        DataCell(
                                          _buildDraggableRowCell(index),
                                        ),

                                      // Serial Number Cell
                                      if (showSerialNumbers)
                                        DataCell(
                                          SizedBox(
                                            width: 60,
                                            child: Text('${index + 1}'),
                                          ),
                                        ),

                                      // Dynamic Data Cells
                                      ...columns.map<DataCell>(
                                        (column) => DataCell(
                                          _buildCellEditor(
                                            column,
                                            rowData[column['id']],
                                            widget.isBuilder
                                                ? (value) => _updateCell(
                                                  index,
                                                  column['id'],
                                                  value,
                                                )
                                                : (value) => _updatePreviewCell(
                                                  index,
                                                  column['id'],
                                                  value,
                                                ),
                                          ),
                                        ),
                                      ),

                                      // Actions Cell
                                      if (widget.isBuilder && allowDeleteRows)
                                        DataCell(
                                          SizedBox(
                                            width: 100,
                                            child: Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.copy,
                                                    size: 18,
                                                  ),
                                                  onPressed:
                                                      () =>
                                                          _duplicateRow(index),
                                                  tooltip: 'Duplicate row',
                                                  color: Colors.blue.shade600,
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    size: 18,
                                                  ),
                                                  onPressed:
                                                      rows.length > minRows
                                                          ? () =>
                                                              _deleteRow(index)
                                                          : null,
                                                  tooltip: 'Delete row',
                                                  color: Colors.red.shade600,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildColumnHeader(
    Map<String, dynamic> column,
    bool allowDeleteColumns,
  ) {
    final columnWidth = _parseColumnWidth(column['width'], column['id']);
    final columnIndex = columns.indexOf(column);

    // Wrap in Draggable for column reordering
    if (widget.isBuilder && (widget.field.props['allowReorderColumns'] ?? true)) {
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
                  column['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: _buildColumnHeaderContent(column, allowDeleteColumns, columnWidth),
        ),
        onDragStarted: () {
          setState(() => draggedColumnId = column['id']);
          debugPrint('🎯 Started dragging column: ${column["name"]}');
        },
        onDragUpdate: (details) {
          _startAutoScroll(details, isColumn: true);
        },
        onDragEnd: (details) {
          _stopAutoScroll(isColumn: true);
          setState(() => draggedColumnId = null);
          debugPrint('🎯 Ended dragging column: ${column["name"]}');
        },
        onDraggableCanceled: (_, __) {
          _stopAutoScroll(isColumn: true);
          setState(() => draggedColumnId = null);
        },
        child: _buildColumnHeaderContent(column, allowDeleteColumns, columnWidth),
      );
    }

    // Not draggable (preview mode or reordering disabled)
    return _buildColumnHeaderContent(column, allowDeleteColumns, columnWidth);
  }

  Widget _buildColumnHeaderContent(
    Map<String, dynamic> column,
    bool allowDeleteColumns,
    double columnWidth,
  ) {
    final fieldTypeIcon = _getFieldTypeIcon(column['type']);
    final isRequired = column['required'] ?? false;
    final columnIndex = columns.indexOf(column);

    // Wrap in DragTarget so columns can be dropped on other columns
    if (widget.isBuilder && (widget.field.props['allowReorderColumns'] ?? true)) {
      return DragTarget<Map<String, dynamic>>(
        onWillAcceptWithDetails: (details) => details.data['type'] == 'column',
        onAcceptWithDetails: (details) {
          final data = details.data;
          final fromIndex = data['columnIndex'] as int;
          final toIndex = columnIndex;
          if (fromIndex != toIndex) {
            _reorderColumn(fromIndex, toIndex);
          }
        },
        builder: (context, candidateData, rejectedData) {
          final isHovered = candidateData.isNotEmpty;
          return Container(
            decoration: BoxDecoration(
              color: isHovered ? Colors.blue.withOpacity(0.1) : Colors.transparent,
              border: isHovered 
                  ? Border.all(color: Colors.blue, width: 2)
                  : null,
              borderRadius: BorderRadius.circular(4),
            ),
            child: _buildColumnHeaderUI(column, allowDeleteColumns, columnWidth, fieldTypeIcon, isRequired),
          );
        },
      );
    }

    return _buildColumnHeaderUI(column, allowDeleteColumns, columnWidth, fieldTypeIcon, isRequired);
  }

  Widget _buildColumnHeaderUI(
    Map<String, dynamic> column,
    bool allowDeleteColumns,
    double columnWidth,
    String fieldTypeIcon,
    bool isRequired,
  ) {

    return SizedBox(
      width: columnWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (widget.isBuilder &&
                  (widget.field.props['allowReorderColumns'] ?? true))
                Icon(
                  Icons.drag_indicator,
                  size: 16,
                  color: draggedColumnId == column['id'] 
                      ? Colors.blue 
                      : Colors.grey.shade400,
                ),
              const SizedBox(width: 4),
              Text(fieldTypeIcon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  column['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isRequired)
                const Text('*', style: TextStyle(color: Colors.red)),
            ],
          ),
          const SizedBox(height: 4),
          if (widget.isBuilder)
            Row(
              children: [
                Expanded(
                  child: Text(
                    _getFieldTypeName(column['type']),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings, size: 16),
                  onPressed: () {
                    setState(() {
                      editingColumn = column;
                    });
                  },
                  tooltip: 'Edit column',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  onPressed: () => _duplicateColumn(column),
                  tooltip: 'Duplicate column',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                if (columns.length > 1 && allowDeleteColumns)
                  IconButton(
                    icon: const Icon(Icons.delete, size: 16),
                    onPressed: () => _deleteColumn(column['id']),
                    tooltip: 'Delete column',
                    color: Colors.red.shade600,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  // Store calculated widths for dynamic distribution
  final Map<String, double> _calculatedWidths = {};

  // Calculate dynamic column widths based on available space
  void _calculateDynamicColumnWidths() {
    // Get container width from context (assume minimum 800px for web)
    final containerWidth = MediaQuery.of(context).size.width;
    // Use 90% of screen width or minimum 800px
    final tableWidth = containerWidth > 900 ? containerWidth * 0.9 : 800.0;

    // Calculate fixed widths
    double fixedWidth = 0;

    // Row numbers column (if shown in builder mode)
    if (widget.isBuilder && (widget.field.props['showRowNumbers'] ?? true)) {
      fixedWidth += 60;
    }

    // Serial numbers column (if shown)
    if (widget.field.props['showSerialNumbers'] ?? false) {
      fixedWidth += 60;
    }

    // Actions column (if shown in builder mode)
    if (widget.isBuilder && (widget.field.props['allowDeleteRows'] ?? true)) {
      fixedWidth += 100;
    }

    // Calculate widths for columns with manual settings
    int autoWidthColumns = 0;
    double manualWidthTotal = 0;

    for (final column in columns) {
      final width = column['width'];
      if (width == null || width == 'auto') {
        autoWidthColumns++;
      } else {
        final widthStr = width.toString();
        if (widthStr.endsWith('px')) {
          final parsed = double.tryParse(widthStr.replaceAll('px', '')) ?? 150.0;
          manualWidthTotal += parsed;
        } else {
          autoWidthColumns++;
        }
      }
    }

    // Calculate available width for auto columns
    final availableWidth = tableWidth - fixedWidth - manualWidthTotal;
    final autoColumnWidth = autoWidthColumns > 0 
        ? (availableWidth / autoWidthColumns).clamp(100.0, 500.0) // Min 100px, Max 500px
        : 150.0;

    // Store calculated widths
    _calculatedWidths.clear();
    for (final column in columns) {
      final columnId = column['id'];
      final width = column['width'];
      
      if (width == null || width == 'auto') {
        _calculatedWidths[columnId] = autoColumnWidth;
      } else {
        final widthStr = width.toString();
        if (widthStr.endsWith('px')) {
          _calculatedWidths[columnId] = double.tryParse(widthStr.replaceAll('px', '')) ?? autoColumnWidth;
        } else {
          _calculatedWidths[columnId] = autoColumnWidth;
        }
      }
    }
  }

  double _parseColumnWidth(dynamic width, String? columnId) {
    // Use pre-calculated width if available
    if (columnId != null && _calculatedWidths.containsKey(columnId)) {
      return _calculatedWidths[columnId]!;
    }

    // Fallback to old behavior
    if (width == null || width == 'auto') return 150.0;

    final widthStr = width.toString();
    if (widthStr.endsWith('px')) {
      return double.tryParse(widthStr.replaceAll('px', '')) ?? 150.0;
    }

    return 150.0;
  }

  String _getFieldTypeIcon(String? type) {
    switch (type) {
      case 'text':
        return '📝';
      case 'email':
        return '📧';
      case 'number':
        return '🔢';
      case 'textarea':
        return '📄';
      case 'select':
        return '📋';
      case 'radio':
        return '⚪';
      case 'checkbox':
        return '☑️';
      case 'checkboxGroup':
        return '☑️';
      case 'date':
        return '📅';
      case 'time':
        return '🕐';
      case 'tel':
        return '📞';
      case 'url':
        return '🌐';
      default:
        return '📝';
    }
  }

  String _getFieldTypeName(String? type) {
    switch (type) {
      case 'text':
        return 'Text';
      case 'email':
        return 'Email';
      case 'number':
        return 'Number';
      case 'textarea':
        return 'Textarea';
      case 'select':
        return 'Select';
      case 'radio':
        return 'Radio';
      case 'checkbox':
        return 'Checkbox';
      case 'checkboxGroup':
        return 'Checkbox Group';
      case 'date':
        return 'Date';
      case 'time':
        return 'Time';
      case 'tel':
        return 'Phone';
      case 'url':
        return 'URL';
      default:
        return 'Field';
    }
  }

  Widget _buildCellEditor(
    Map<String, dynamic> column,
    dynamic value,
    Function(dynamic) onChanged,
  ) {
    final columnType = column['type']?.toString() ?? 'text';
    final fieldProps = Map<String, dynamic>.from(
      column['fieldProps'] as Map<String, dynamic>? ?? {},
    );
    
    // Sanitize options for dropdown field types
    if (['select', 'radio', 'checkboxGroup'].contains(columnType)) {
      fieldProps['options'] = _sanitizeOptions(fieldProps['options']);
    }
    
    final columnWidth = _parseColumnWidth(column['width'], column['id']);

    return SizedBox(
      width: columnWidth,
      child: _buildFieldInput(columnType, value, onChanged, fieldProps),
    );
  }

  Widget _buildFieldInput(
    String type,
    dynamic value,
    Function(dynamic) onChanged,
    Map<String, dynamic> props,
  ) {
    switch (type) {
      case 'number':
        return _TableCellTextField(
          initialValue: value?.toString() ?? '',
          onChanged: (val) => onChanged(num.tryParse(val)),
          keyboardType: TextInputType.number,
          hintText: props['placeholder']?.toString(),
        );

      case 'select':
        final options =
            (props['options'] as List?)?.map((e) => e.toString()).toList() ??
            [];
        
        // FIX: Remove duplicates and empty options
        final uniqueOptions = options
            .where((option) => option.trim().isNotEmpty)
            .toSet()
            .toList();
        
        // FIX: Ensure there's at least one option
        if (uniqueOptions.isEmpty) {
          uniqueOptions.add('No options available');
        }
        
        return DropdownButtonFormField<String>(
          initialValue: uniqueOptions.contains(value?.toString()) ? value.toString() : null,
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          items:
              uniqueOptions.map((option) {
                return DropdownMenuItem(
                  value: option,
                  child: Text(option, style: const TextStyle(fontSize: 13)),
                );
              }).toList(),
          onChanged: (newValue) {
            if (newValue != null) onChanged(newValue);
          },
        );

      case 'radio':
        final options =
            (props['options'] as List?)?.map((e) => e.toString()).toList() ??
            [];
        
        // FIX: Remove duplicates and empty options
        final uniqueOptions = options
            .where((option) => option.trim().isNotEmpty)
            .toSet()
            .toList();
        
        // FIX: Ensure there's at least one option
        if (uniqueOptions.isEmpty) {
          uniqueOptions.add('No options available');
        }
        
        return DropdownButtonFormField<String>(
          initialValue: uniqueOptions.contains(value?.toString()) ? value.toString() : null,
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          items:
              uniqueOptions.map((option) {
                return DropdownMenuItem(
                  value: option,
                  child: Text(option, style: const TextStyle(fontSize: 13)),
                );
              }).toList(),
          onChanged: (newValue) {
            if (newValue != null) onChanged(newValue);
          },
        );

      case 'checkbox':
        return Checkbox(
          value: value == true,
          onChanged: (checked) => onChanged(checked ?? false),
        );

      case 'checkboxGroup':
        final options =
            (props['options'] as List?)?.map((e) => e.toString()).toList() ??
            [];
        
        // FIX: Remove duplicates and empty options
        final uniqueOptions = options
            .where((option) => option.trim().isNotEmpty)
            .toSet()
            .toList();
        
        final selectedValues =
            value is List
                ? value.map((e) => e.toString()).toList()
                : <String>[];

        return PopupMenuButton<String>(
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Text(
              selectedValues.isEmpty
                  ? 'Select...'
                  : '${selectedValues.length} selected',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          itemBuilder: (context) {
            return uniqueOptions.map((option) {
              return CheckedPopupMenuItem<String>(
                value: option,
                checked: selectedValues.contains(option),
                child: Text(option, style: const TextStyle(fontSize: 13)),
              );
            }).toList();
          },
          onSelected: (option) {
            final newValues = List<String>.from(selectedValues);
            if (newValues.contains(option)) {
              newValues.remove(option);
            } else {
              newValues.add(option);
            }
            onChanged(newValues);
          },
        );

      case 'date':
        return InkWell(
          onTap: () => _selectDate(onChanged, value),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Text(
              value?.toString() ?? 'Select date',
              style: TextStyle(
                fontSize: 13,
                color: value == null ? Colors.grey.shade600 : Colors.black87,
              ),
            ),
          ),
        );

      case 'time':
        return InkWell(
          onTap: () => _selectTime(onChanged, value),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Text(
              value?.toString() ?? 'Select time',
              style: TextStyle(
                fontSize: 13,
                color: value == null ? Colors.grey.shade600 : Colors.black87,
              ),
            ),
          ),
        );

      case 'textarea':
        return _TableCellTextField(
          initialValue: value?.toString() ?? '',
          onChanged: onChanged,
          maxLines: props['rows'] ?? 4,
          hintText: props['placeholder']?.toString(),
        );

      default: // text, email, url, tel
        return _TableCellTextField(
          initialValue: value?.toString() ?? '',
          onChanged: onChanged,
          hintText: props['placeholder']?.toString(),
        );
    }
  }

  Future<void> _selectDate(
    Function(dynamic) onChanged,
    dynamic currentValue,
  ) async {
    DateTime? initialDate;
    if (currentValue != null) {
      try {
        initialDate = DateTime.parse(currentValue.toString());
      } catch (_) {
        initialDate = DateTime.now();
      }
    } else {
      initialDate = DateTime.now();
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      onChanged(picked.toIso8601String().split('T')[0]);
    }
  }

  Future<void> _selectTime(
    Function(dynamic) onChanged,
    dynamic currentValue,
  ) async {
    TimeOfDay? initialTime;
    if (currentValue != null) {
      try {
        final parts = currentValue.toString().split(':');
        initialTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      } catch (_) {
        initialTime = TimeOfDay.now();
      }
    } else {
      initialTime = TimeOfDay.now();
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      onChanged(
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
      );
    }
  }

  Widget _buildFooterInfo() {
    if (!widget.isBuilder) {
      // In preview mode, show minimal info or hide footer
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Row(
          children: [
            Icon(Icons.table_chart, size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              '${columns.length} columns • ${displayData.length} rows',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    // Builder mode: Show detailed info
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(
            '${columns.length} columns • ${rows.length} rows',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // Column Operations
  void _addColumn(String fieldType) {
    final newColumn = {
      'id':
          'col_${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4().substring(0, 8)}',
      'name': 'New ${_getFieldTypeName(fieldType)}',
      'type': fieldType,
      'label': 'New ${_getFieldTypeName(fieldType)}',
      'required': false,
      'width': 'auto',
      'fieldProps': _getDefaultFieldProps(fieldType),
    };

    setState(() {
      columns.add(newColumn);
      showColumnTypeSelector = false;
      _updateFieldData();
    });
  }

  Map<String, dynamic> _getDefaultFieldProps(String type) {
    switch (type) {
      case 'select':
      case 'radio':
      case 'checkboxGroup':
        return {
          'options': ['Option 1', 'Option 2', 'Option 3'],
        };
      case 'number':
        return {
          'placeholder': 'Enter number...',
          'min': 0,
          'max': 1000,
          'step': 1,
        };
      case 'textarea':
        return {'placeholder': 'Enter text...', 'rows': 4};
      default:
        return {
          'placeholder': 'Enter ${_getFieldTypeName(type).toLowerCase()}...',
        };
    }
  }

  // Sanitize column options to prevent duplicate values error
  List<String> _sanitizeOptions(dynamic options) {
    if (options == null) return ['Option 1', 'Option 2', 'Option 3'];
    
    final List<String> optionsList;
    if (options is List) {
      optionsList = options.map((e) => e.toString()).toList();
    } else {
      return ['Option 1', 'Option 2', 'Option 3'];
    }
    
    // Remove duplicates and empty values
    final uniqueOptions = optionsList
        .where((option) => option.trim().isNotEmpty)
        .toSet()
        .toList();
    
    // Ensure at least one option
    if (uniqueOptions.isEmpty) {
      return ['No options available'];
    }
    
    return uniqueOptions;
  }

  void _deleteColumn(String columnId) {
    if (columns.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Table must have at least one column'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      columns.removeWhere((c) => c['id'] == columnId);
      // Remove data from all rows for this column
      for (var row in rows) {
        (row['data'] as Map<String, dynamic>).remove(columnId);
      }
      _updateFieldData();
    });
  }

  void _duplicateColumn(Map<String, dynamic> column) {
    final newColumn = Map<String, dynamic>.from(column);
    newColumn['id'] =
        'col_${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4().substring(0, 8)}';
    newColumn['name'] = '${column['name']} Copy';

    setState(() {
      columns.add(newColumn);
      _updateFieldData();
    });
  }

  // ==================== COLUMN REORDERING ====================
  
  void _reorderColumn(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    
    setState(() {
      debugPrint('📊 Reordering column from $oldIndex to $newIndex');
      
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      
      final column = columns.removeAt(oldIndex);
      columns.insert(newIndex, column);
      
      _updateFieldData();
    });
  }

  // ==================== ROW REORDERING ====================
  
  void _reorderRow(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    
    setState(() {
      debugPrint('📊 Reordering row from $oldIndex to $newIndex');
      
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      
      final row = rows.removeAt(oldIndex);
      rows.insert(newIndex, row);
      
      _updateFieldData();
    });
  }

void _startAutoScroll(DragUpdateDetails details, {required bool isColumn}) {
  final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
  if (renderBox == null) return;

  final localPosition = renderBox.globalToLocal(details.globalPosition);
  final size = renderBox.size;
  
  const edgeZone = 80.0;
  const scrollSpeed = 8.0;

  if (isColumn) {
    _horizontalScrollTimer?.cancel();
    
    if (_horizontalScrollController.hasClients) {
      final atLeftEdge = localPosition.dx < edgeZone;
      final atRightEdge = localPosition.dx > size.width - edgeZone;
      
      if (atLeftEdge || atRightEdge) {
        _horizontalScrollTimer = Timer.periodic(
          const Duration(milliseconds: 50),
          (timer) {
            if (!_horizontalScrollController.hasClients) {
              timer.cancel();
              return;
            }
            
            final offset = _horizontalScrollController.offset;
            final maxScroll = _horizontalScrollController.position.maxScrollExtent;
            
            if (atLeftEdge && offset > 0) {
              _horizontalScrollController.jumpTo(
                (offset - scrollSpeed).clamp(0.0, maxScroll),
              );
            } else if (atRightEdge && offset < maxScroll) {
              _horizontalScrollController.jumpTo(
                (offset + scrollSpeed).clamp(0.0, maxScroll),
              );
            } else {
              timer.cancel();
            }
          },
        );
      }
    }
  } else {
    _verticalScrollTimer?.cancel();
    
    if (_verticalScrollController.hasClients) {
      final atTopEdge = localPosition.dy < edgeZone;
      final atBottomEdge = localPosition.dy > size.height - edgeZone;
      
      if (atTopEdge || atBottomEdge) {
        _verticalScrollTimer = Timer.periodic(
          const Duration(milliseconds: 50),
          (timer) {
            if (!_verticalScrollController.hasClients) {
              timer.cancel();
              return;
            }
            
            final offset = _verticalScrollController.offset;
            final maxScroll = _verticalScrollController.position.maxScrollExtent;
            
            if (atTopEdge && offset > 0) {
              _verticalScrollController.jumpTo(
                (offset - scrollSpeed).clamp(0.0, maxScroll),
              );
            } else if (atBottomEdge && offset < maxScroll) {
              _verticalScrollController.jumpTo(
                (offset + scrollSpeed).clamp(0.0, maxScroll),
              );
            } else {
              timer.cancel();
            }
          },
        );
      }
    }
  }
}

void _stopAutoScroll({required bool isColumn}) {
  if (isColumn) {
    _horizontalScrollTimer?.cancel();
    _horizontalScrollTimer = null;
  } else {
    _verticalScrollTimer?.cancel();
    _verticalScrollTimer = null;
  }
}
  // ==================== BUILD DRAGGABLE ROW CELL ====================
  
Widget _buildDraggableRowCell(int index) {
  final rowId = rows[index]['id'].toString();
  final allowReorder = widget.field.props['allowReorderRows'] ?? true;
  
  if (!widget.isBuilder || !allowReorder) {
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
  
  // Wrap in DragTarget so rows can be dropped on other rows
  return DragTarget<Map<String, dynamic>>(
    onWillAcceptWithDetails: (details) => details.data['type'] == 'row',
    onAcceptWithDetails: (details) {
      final data = details.data;
      final fromIndex = data['rowIndex'] as int;
      final toIndex = index;
      if (fromIndex != toIndex) {
        _reorderRow(fromIndex, toIndex);
      }
    },
    builder: (context, candidateData, rejectedData) {
      final isHovered = candidateData.isNotEmpty;
     
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
          setState(() => draggedRowId = rowId);
          debugPrint('🎯 Started dragging row ${index + 1}');
        },
        onDragUpdate: (details) {
          _startAutoScroll(details, isColumn: false);
        },
        onDragEnd: (details) {
          _stopAutoScroll(isColumn: false);
          setState(() => draggedRowId = null);
          debugPrint('🎯 Ended dragging row ${index + 1}');
        },
        onDraggableCanceled: (_, __) {
          _stopAutoScroll(isColumn: false);
          setState(() => draggedRowId = null);
        },
        child: Container(
          decoration: BoxDecoration(
            color: isHovered ? Colors.green.withOpacity(0.1) : Colors.transparent,
            border: isHovered
                ? Border.all(color: Colors.green, width: 2)
                : null,
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.all(4),
          child: SizedBox(
            width: 52,
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
        ),
      );
    },
  );
}

  // ==================== BUILD COLUMN DROP TARGET ====================
  
  Widget _buildColumnDropTarget(int targetIndex) {
    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (details) => details.data['type'] == 'column',
      onAcceptWithDetails: (details) {
        final data = details.data;
        final fromIndex = data['columnIndex'] as int;
        _reorderColumn(fromIndex, targetIndex);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
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
      },
    );
  }

  // ==================== BUILD ROW DROP TARGET ====================
  
  Widget _buildRowDropTarget(int targetIndex, int columnsCount) {
    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (details) => details.data['type'] == 'row',
      onAcceptWithDetails: (details) {
        final data = details.data;
        final fromIndex = data['rowIndex'] as int;
        _reorderRow(fromIndex, targetIndex);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        return Container(
          height: isHovered ? 40 : 4,
          decoration: BoxDecoration(
            color: isHovered ? Colors.green[100] : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: isHovered
              ? Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle, color: Colors.green[700], size: 18),
                      const SizedBox(width: 4),
                      Text(
                        'Drop here',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              : null,
        );
      },
    );
  }

  // Row Operations
  void _addRow() {
    setState(() {
      rows.add(_createEmptyRow());
      _updateFieldData();
    });
  }

  void _deleteRow(int index) {
    final minRows = widget.field.props['minRows'] ?? 1;
    if (rows.length <= minRows) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Table must have at least $minRows row(s)'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      rows.removeAt(index);
      _updateFieldData();
    });
  }

  void _duplicateRow(int index) {
    final originalRow = rows[index];
    final newRow = {
      'id':
          'row_${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4().substring(0, 8)}',
      'data': Map<String, dynamic>.from(originalRow['data'] as Map),
    };

    setState(() {
      rows.insert(index + 1, newRow);
      _updateFieldData();
    });
  }

  void _updateCell(int rowIndex, String columnId, dynamic value) {
    // Builder mode: Update configuration rows
    setState(() {
      (rows[rowIndex]['data'] as Map<String, dynamic>)[columnId] = value;
      _updateFieldData();
    });
  }

  void _updatePreviewCell(int rowIndex, String columnId, dynamic value) {
    // Preview mode: Update display data and notify parent
    setState(() {
      (displayData[rowIndex]['data'] as Map<String, dynamic>)[columnId] = value;
      _updatePreviewData();
    });
  }

  // Export Functionality (FIX #3: Enhanced with copy to clipboard)
  void _exportToCSV() {
    final headers = <String>[];

    // Add serial numbers header if enabled
    if (widget.field.props['showSerialNumbers'] ?? false) {
      headers.add('S.No');
    }

    // Add column headers
    headers.addAll(columns.map((col) => col['name'].toString()));

    final csvRows = <String>[];
    csvRows.add(headers.join(','));

    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final rowData = row['data'] as Map<String, dynamic>;
      final csvCells = <String>[];

      // Add serial number if enabled
      if (widget.field.props['showSerialNumbers'] ?? false) {
        csvCells.add('${i + 1}');
      }

      // Add cell values
      for (var column in columns) {
        final value = rowData[column['id']] ?? '';
        csvCells.add('"${value.toString().replaceAll('"', '""')}"');
      }

      csvRows.add(csvCells.join(','));
    }

    final csvContent = csvRows.join('\n');

    // Show enhanced export dialog with copy and download options
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.file_download, color: Colors.blue),
            const SizedBox(width: 8),
            Text('Export CSV - ${widget.field.label}'),
          ],
        ),
        content: SizedBox(
          width: 500,
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${rows.length} rows × ${columns.length} columns',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.grey.shade50,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      csvContent,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              // Copy to clipboard
              await _copyToClipboard(csvContent);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Text('CSV copied to clipboard!'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            icon: const Icon(Icons.content_copy, size: 18),
            label: const Text('Copy to Clipboard'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _downloadCSV(csvContent),
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Download CSV'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Copy CSV content to clipboard
  Future<void> _copyToClipboard(String content) async {
    // For web platform, use the web clipboard API
    try {
      // Create a temporary textarea element
      final textarea = html.TextAreaElement();
      textarea.value = content;
      html.document.body!.append(textarea);
      textarea.select();
      html.document.execCommand('copy');
      textarea.remove();
    } catch (e) {
      debugPrint('Copy to clipboard failed: $e');
    }
  }

  // Download CSV file
  void _downloadCSV(String content) {
    try {
      // Create a blob with the CSV content
      final blob = html.Blob([content], 'text/csv');
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      // Create a temporary anchor element and trigger download
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', '${widget.field.label.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.csv')
        ..click();
      
      // Clean up
      html.Url.revokeObjectUrl(url);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('CSV file downloaded successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text('Download failed: $e'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

/// Column Settings Form Widget
class ColumnSettingsForm extends StatefulWidget {
  final Map<String, dynamic> column;
  final Function(Map<String, dynamic>) onSave;
  final VoidCallback onCancel;

  const ColumnSettingsForm({
    super.key,
    required this.column,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<ColumnSettingsForm> createState() => _ColumnSettingsFormState();
}

class _ColumnSettingsFormState extends State<ColumnSettingsForm> {
  late Map<String, dynamic> editedColumn;
  late TextEditingController nameController;
  late TextEditingController optionsController;

  @override
  void initState() {
    super.initState();
    editedColumn = Map<String, dynamic>.from(widget.column);
    editedColumn['fieldProps'] = Map<String, dynamic>.from(
      widget.column['fieldProps'] ?? {},
    );
    nameController = TextEditingController(text: editedColumn['name']);

    // Initialize options controller
    final options = editedColumn['fieldProps']['options'];
    if (options is List) {
      optionsController = TextEditingController(text: options.join('\n'));
    } else {
      optionsController = TextEditingController();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    optionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Text(
              'Edit Column Settings',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: widget.onCancel,
              icon: const Icon(Icons.close),
              label: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                // Save options if select/radio/checkboxGroup field type
                if ([
                  'select',
                  'radio',
                  'checkboxGroup',
                ].contains(editedColumn['type'])) {
                  final options =
                      optionsController.text
                          .split('\n')
                          .where((s) => s.trim().isNotEmpty)
                          .map((s) => s.trim())
                          .toList();
                  editedColumn['fieldProps']['options'] = options;
                }
                widget.onSave(editedColumn);
              },
              icon: const Icon(Icons.check),
              label: const Text('Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),

        // Column Name
        TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Column Name',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            editedColumn['name'] = value;
            editedColumn['label'] = value;
          },
        ),
        const SizedBox(height: 16),

        // Required Checkbox
        CheckboxListTile(
          title: const Text('Required Field'),
          value: editedColumn['required'] ?? false,
          onChanged: (value) {
            setState(() {
              editedColumn['required'] = value;
            });
          },
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 16),

        // Column Width
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Column Width',
            border: OutlineInputBorder(),
          ),
          initialValue: editedColumn['width'] ?? 'auto',
          items: const [
            DropdownMenuItem(value: 'auto', child: Text('Auto')),
            DropdownMenuItem(value: '100px', child: Text('Small (100px)')),
            DropdownMenuItem(
              value: '150px',
              child: Text('Medium-Small (150px)'),
            ),
            DropdownMenuItem(value: '200px', child: Text('Medium (200px)')),
            DropdownMenuItem(value: '300px', child: Text('Large (300px)')),
            DropdownMenuItem(
              value: '400px',
              child: Text('Extra Large (400px)'),
            ),
            DropdownMenuItem(value: '500px', child: Text('XXL (500px)')),
          ],
          onChanged: (value) {
            setState(() {
              editedColumn['width'] = value;
            });
          },
        ),
        const SizedBox(height: 16),

        // Field-Specific Settings
        if (['select', 'radio', 'checkboxGroup'].contains(editedColumn['type']))
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Options (one per line)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: optionsController,
                maxLines: 6,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Option 1\nOption 2\nOption 3',
                ),
              ),
            ],
          ),
      ],
    );
  }
}
 
/// Stateful TextField for Table Cells
/// Prevents cursor reset by maintaining its own controller
class _TableCellTextField extends StatefulWidget {
  final String initialValue;
  final Function(String) onChanged;
  final TextInputType? keyboardType;
  final int? maxLines;
  final String? hintText;

  const _TableCellTextField({
    required this.initialValue,
    required this.onChanged,
    this.keyboardType,
    this.maxLines,
    this.hintText,
  });

  @override
  State<_TableCellTextField> createState() => _TableCellTextFieldState();
}

class _TableCellTextFieldState extends State<_TableCellTextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isInternalUpdate = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controller = TextEditingController(text: widget.initialValue);
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (!_isInternalUpdate) {
      widget.onChanged(_controller.text);
    }
  }

  @override
  void didUpdateWidget(_TableCellTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Only update if value changed and field not focused
    if (widget.initialValue != oldWidget.initialValue && 
        widget.initialValue != _controller.text &&
        !_focusNode.hasFocus) {
      _isInternalUpdate = true;
      _controller.text = widget.initialValue;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: widget.initialValue.length),
      );
      _isInternalUpdate = false;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      keyboardType: widget.keyboardType,
      maxLines: widget.maxLines ?? 1,
      decoration: InputDecoration(
        hintText: widget.hintText,
        border: InputBorder.none,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 8,
        ),
      ),
      style: const TextStyle(fontSize: 13),
    );
  }
}
