import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/workflow_node.dart' as wf;
import '../models/workflow_edge.dart';

class WorkflowCanvas extends StatefulWidget {
  final List<wf.WorkflowNode> nodes;
  final List<WorkflowEdge> edges;
  final Function(String nodeId, Offset position) onNodeDrag;
  final Function(String nodeId) onNodeTap;
  final bool connectionMode;
  final String? connectionSource;
  final Function(String nodeId)? onStartConnection;
  final Function(String nodeId)? onCompleteConnection;
  final Function()? onCancelConnection;
  final Function(String edgeId)? onDeleteEdge;
  final bool readonly;

  const WorkflowCanvas({
    Key? key,
    required this.nodes,
    required this.edges,
    required this.onNodeDrag,
    required this.onNodeTap,
    this.connectionMode = false,
    this.connectionSource,
    this.onStartConnection,
    this.onCompleteConnection,
    this.onCancelConnection,
    this.onDeleteEdge,
    this.readonly = false,
  }) : super(key: key);

  @override
  State<WorkflowCanvas> createState() => _WorkflowCanvasState();
}

class _WorkflowCanvasState extends State<WorkflowCanvas> {
  static const double gridSize = 40.0;
  static const double nodeWidth = 200.0;
  static const double nodeHeight = 80.0;

  bool _dragMode = false;
  String? _draggedNodeId;
  Offset _dragOffset = Offset.zero;
  Offset _mousePosition = Offset.zero;
  Offset? _dragStartPosition;
  static const double _dragThreshold = 5.0;
  bool _justFinishedDrag = false;

  Offset _snapToGrid(Offset position) {
    return Offset(
      (position.dx / gridSize).round() * gridSize,
      (position.dy / gridSize).round() * gridSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) {
        setState(() {
          _mousePosition = event.localPosition;
        });
      },
      child: GestureDetector(
        onTap: () {
          if (widget.connectionMode) {
            widget.onCancelConnection?.call();
          }
        },
        child: Listener(
          onPointerMove: _handlePointerMove,
          onPointerUp: _handlePointerUp,
          child: Container(
            width: 2200,
            height: 1400,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.green.shade100,
                  Colors.blue.shade50,
                  Colors.indigo.shade50,
                ],
              ),
            ),
            child: Stack(
              children: [
                CustomPaint(
                  painter: GridPainter(),
                  size: const Size(2200, 1400),
                ),
                CustomPaint(
                  painter: EdgesPainter(
                    nodes: widget.nodes,
                    edges: widget.edges,
                    connectionMode: widget.connectionMode,
                    connectionSource: widget.connectionSource,
                    mousePosition: _mousePosition,
                    nodeWidth: nodeWidth,
                    nodeHeight: nodeHeight,
                  ),
                  size: const Size(2200, 1400),
                ),
                if (!widget.readonly)
                  ...widget.edges.map((edge) => _buildEdgeDeleteButton(edge)),
                ...widget.nodes.map((node) => _buildNode(node)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handlePointerMove(PointerEvent event) {
    if (widget.readonly) return;
    
    setState(() {
      _mousePosition = event.localPosition;
    });

    if (_draggedNodeId != null && _dragStartPosition != null) {
      final distance = (event.localPosition - _dragStartPosition!).distance;
      
      if (distance > _dragThreshold) {
        if (!_dragMode) {
          setState(() {
            _dragMode = true;
          });
        }
        
        final rawX = math.max(0.0, event.localPosition.dx - _dragOffset.dx);
        final rawY = math.max(0.0, event.localPosition.dy - _dragOffset.dy);
        final snappedPos = _snapToGrid(Offset(rawX, rawY));
        
        widget.onNodeDrag(_draggedNodeId!, snappedPos);
      }
    }
  }

  void _handlePointerUp(PointerEvent event) {
    final wasDragging = _dragMode;
    
    if (_draggedNodeId != null) {
      setState(() {
        _dragMode = false;
        _draggedNodeId = null;
        _dragOffset = Offset.zero;
        _dragStartPosition = null;
        
        if (wasDragging) {
          _justFinishedDrag = true;
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              setState(() {
                _justFinishedDrag = false;
              });
            }
          });
        }
      });
    }
  }

  Widget _buildNode(wf.WorkflowNode node) {
    final isApprovalNode = node.type == 'approval' || node.type == 'interview' || node.type == 'panelist';
    final isOutcomeNode = node.type == 'outcome';
    final isConnectionSource = widget.connectionSource == node.id;
    final isDragging = _dragMode && _draggedNodeId == node.id;

    Color nodeColor;
    Color nodeBorderColor;
    Color textColor;
    
    if (isOutcomeNode && node.data.outcome != null) {
      switch (node.data.outcome!.toLowerCase()) {
        case 'approved':
          nodeColor = const Color(0xFFDCFCE7);
          nodeBorderColor = const Color(0xFF10B981);
          textColor = const Color(0xFF065F46);
          break;
        case 'rejected':
          nodeColor = const Color(0xFFFEE2E2);
          nodeBorderColor = const Color(0xFFEF4444);
          textColor = const Color(0xFF991B1B);
          break;
        case 'hold':
          nodeColor = const Color(0xFFFEF3C7);
          nodeBorderColor = const Color(0xFFF59E0B);
          textColor = const Color(0xFF92400E);
          break;
        default:
          nodeColor = Colors.grey.shade100;
          nodeBorderColor = Colors.grey.shade400;
          textColor = Colors.grey.shade800;
      }
    } else {
      nodeColor = const Color(0xFFEFF6FF);
      nodeBorderColor = const Color(0xFF3B82F6);
      textColor = const Color(0xFF1E40AF);
    }

    return Positioned(
      left: node.position.dx,
      top: node.position.dy,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: widget.connectionMode || widget.readonly ? null : (details) {
          setState(() {
            _dragOffset = Offset(
              details.localPosition.dx,
              details.localPosition.dy,
            );
            _draggedNodeId = node.id;
            _dragStartPosition = details.globalPosition;
          });
        },
        onPanUpdate: widget.connectionMode || widget.readonly ? null : (details) {
          if (_draggedNodeId == node.id && _dragStartPosition != null) {
            final distance = (details.globalPosition - _dragStartPosition!).distance;
            
            if (distance > _dragThreshold) {
              if (!_dragMode) {
                setState(() {
                  _dragMode = true;
                });
              }
              
              final rawPos = Offset(
                node.position.dx + details.delta.dx,
                node.position.dy + details.delta.dy,
              );
              final snappedPos = _snapToGrid(rawPos);
              
              widget.onNodeDrag(node.id, snappedPos);
            }
          }
        },
        onPanEnd: widget.connectionMode || widget.readonly ? null : (details) {
          final wasDragging = _dragMode;
          
          setState(() {
            _dragMode = false;
            _draggedNodeId = null;
            _dragOffset = Offset.zero;
            _dragStartPosition = null;
            
            if (wasDragging) {
              _justFinishedDrag = true;
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) {
                  setState(() {
                    _justFinishedDrag = false;
                  });
                }
              });
            }
          });
        },
        onTap: () {
          if (!_dragMode && !_justFinishedDrag) {
            if (widget.connectionMode) {
              if (widget.connectionSource != node.id) {
                widget.onCompleteConnection?.call(node.id);
              }
            } else {
              widget.onNodeTap(node.id);
            }
          }
        },
        child: MouseRegion(
          cursor: widget.connectionMode 
              ? SystemMouseCursors.click 
              : widget.readonly
                  ? SystemMouseCursors.basic
                  : isDragging
                      ? SystemMouseCursors.grabbing
                      : SystemMouseCursors.grab,
          child: Container(
            width: nodeWidth,
            height: nodeHeight,
            decoration: BoxDecoration(
              color: nodeColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isConnectionSource
                    ? Colors.purple.shade600
                    : nodeBorderColor,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDragging ? 0.25 : 0.12),
                  blurRadius: isDragging ? 20 : 12,
                  offset: isDragging ? const Offset(0, 8) : const Offset(0, 4),
                  spreadRadius: isDragging ? 2 : 0,
                ),
              ],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        node.data.label,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          letterSpacing: 0.2,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (node.data.employeeName != null && node.data.employeeName!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '👤 ${node.data.employeeName}',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!widget.readonly && isApprovalNode)
                  Positioned(
                    right: -14,
                    top: nodeHeight / 2 - 14,
                    child: GestureDetector(
                      onTap: () {
                        widget.onStartConnection?.call(node.id);
                      },
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isConnectionSource 
                                ? Colors.purple.shade600 
                                : Colors.blue.shade600,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (!widget.readonly && widget.connectionMode && widget.connectionSource != node.id)
                  Positioned(
                    left: -14,
                    top: nodeHeight / 2 - 14,
                    child: GestureDetector(
                      onTap: () {
                        widget.onCompleteConnection?.call(node.id);
                      },
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.green.shade500,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.circle,
                              color: Colors.white,
                              size: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (isDragging)
                  Positioned(
                    top: -35,
                    left: nodeWidth / 2 - 50,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'x: ${node.position.dx.round()}, y: ${node.position.dy.round()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEdgeDeleteButton(WorkflowEdge edge) {
    final sourceNode = widget.nodes.firstWhere(
      (n) => n.id == edge.source,
      orElse: () => wf.WorkflowNode(
        id: '',
        type: 'approval',
        position: Offset.zero,
        data: wf.WorkflowNodeData(label: '', title: '', color: Colors.blue),
      ),
    );
    
    final targetNode = widget.nodes.firstWhere(
      (n) => n.id == edge.target,
      orElse: () => wf.WorkflowNode(
        id: '',
        type: 'approval',
        position: Offset.zero,
        data: wf.WorkflowNodeData(label: '', title: '', color: Colors.blue),
      ),
    );

    if (sourceNode.id.isEmpty || targetNode.id.isEmpty) {
      return const SizedBox.shrink();
    }

    final startX = sourceNode.position.dx + nodeWidth;
    final startY = sourceNode.position.dy + nodeHeight / 2;
    final endX = targetNode.position.dx;
    final endY = targetNode.position.dy + nodeHeight / 2;
    
    final midX = (startX + endX) / 2;
    final midY = (startY + endY) / 2;

    return Positioned(
      left: midX - 14,
      top: midY + 20,
      child: GestureDetector(
        onTap: () {
          widget.onDeleteEdge?.call(edge.id);
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final smallGridPaint = Paint()
      ..color = Colors.grey.shade300.withOpacity(0.4)
      ..strokeWidth = 0.5;

    final largeGridPaint = Paint()
      ..color = Colors.grey.shade400.withOpacity(0.6)
      ..strokeWidth = 1;

    const gridSize = 40.0;
    const largeGridSize = gridSize * 5;

    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        smallGridPaint,
      );
    }

    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        smallGridPaint,
      );
    }

    for (double x = 0; x < size.width; x += largeGridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        largeGridPaint,
      );
    }

    for (double y = 0; y < size.height; y += largeGridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        largeGridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) => false;
}

class EdgesPainter extends CustomPainter {
  final List<wf.WorkflowNode> nodes;
  final List<WorkflowEdge> edges;
  final bool connectionMode;
  final String? connectionSource;
  final Offset mousePosition;
  final double nodeWidth;
  final double nodeHeight;

  EdgesPainter({
    required this.nodes,
    required this.edges,
    required this.connectionMode,
    required this.connectionSource,
    required this.mousePosition,
    required this.nodeWidth,
    required this.nodeHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final edge in edges) {
      _drawEdge(canvas, edge);
    }

    if (connectionMode && connectionSource != null) {
      final sourceNode = nodes.firstWhere(
        (n) => n.id == connectionSource,
        orElse: () => wf.WorkflowNode(
          id: '',
          type: 'approval',
          position: Offset.zero,
          data: wf.WorkflowNodeData(label: '', title: '', color: Colors.blue),
        ),
      );

      if (sourceNode.id.isNotEmpty) {
        final startPoint = Offset(
          sourceNode.position.dx + nodeWidth,
          sourceNode.position.dy + nodeHeight / 2,
        );

        final paint = Paint()
          ..color = Colors.purple.shade600
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke;

        _drawDashedLine(canvas, startPoint, mousePosition, paint, dashLength: 12, gapLength: 6);
        _drawArrowHead(canvas, mousePosition, (mousePosition - startPoint).direction, Colors.purple.shade600);
      }
    }
  }

  void _drawEdge(Canvas canvas, WorkflowEdge edge) {
    final sourceNode = nodes.firstWhere(
      (n) => n.id == edge.source,
      orElse: () => wf.WorkflowNode(
        id: '',
        type: 'approval',
        position: Offset.zero,
        data: wf.WorkflowNodeData(label: '', title: '', color: Colors.blue),
      ),
    );
    
    final targetNode = nodes.firstWhere(
      (n) => n.id == edge.target,
      orElse: () => wf.WorkflowNode(
        id: '',
        type: 'approval',
        position: Offset.zero,
        data: wf.WorkflowNodeData(label: '', title: '', color: Colors.blue),
      ),
    );

    if (sourceNode.id.isEmpty || targetNode.id.isEmpty) {
      return;
    }

    final startPoint = Offset(
      sourceNode.position.dx + nodeWidth,
      sourceNode.position.dy + nodeHeight / 2,
    );
    
    final endPoint = Offset(
      targetNode.position.dx,
      targetNode.position.dy + nodeHeight / 2,
    );

    Color edgeColor;
    
    final condition = edge.data?['condition'] as String?;
    final labelLower = edge.label.toLowerCase();
    
    if (labelLower.contains('approved') || condition == 'approved') {
      edgeColor = const Color(0xFF10B981);
    } else if (labelLower.contains('rejected') || condition == 'rejected') {
      edgeColor = const Color(0xFFEF4444);
    } else if (labelLower.contains('hold') || condition == 'hold') {
      edgeColor = const Color(0xFFF59E0B);
    } else {
      edgeColor = const Color(0xFF3B82F6);
    }

    final paint = Paint()
      ..color = edgeColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(startPoint, endPoint, paint);
    _drawArrowHead(canvas, endPoint, (endPoint - startPoint).direction, edgeColor);

    if (edge.label.isNotEmpty) {
      final midPoint = Offset(
        (startPoint.dx + endPoint.dx) / 2,
        (startPoint.dy + endPoint.dy) / 2,
      );
      _drawLabel(canvas, midPoint, edge.label, edgeColor);
    }
  }

  void _drawArrowHead(Canvas canvas, Offset point, double angle, Color color) {
    const arrowSize = 14.0;
    const arrowAngle = 0.4;
    
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final strokePaint = Paint()
      ..color = color.withOpacity(0.8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(point.dx, point.dy)
      ..lineTo(
        point.dx - arrowSize * math.cos(angle - arrowAngle),
        point.dy - arrowSize * math.sin(angle - arrowAngle),
      )
      ..lineTo(
        point.dx - arrowSize * math.cos(angle + arrowAngle),
        point.dy - arrowSize * math.sin(angle + arrowAngle),
      )
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);
  }

  void _drawLabel(Canvas canvas, Offset position, String label, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    
    final backgroundRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: position,
        width: textPainter.width + 24,
        height: 26,
      ),
      const Radius.circular(13),
    );
    
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    
    final shadowRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: position.translate(0, 2),
        width: textPainter.width + 24,
        height: 26,
      ),
      const Radius.circular(13),
    );
    
    canvas.drawRRect(shadowRect, shadowPaint);
    
    final backgroundPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    
    canvas.drawRRect(backgroundRect, backgroundPaint);
    canvas.drawRRect(backgroundRect, borderPaint);
    
    textPainter.paint(
      canvas,
      Offset(
        position.dx - textPainter.width / 2,
        position.dy - textPainter.height / 2,
      ),
    );
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint, {double dashLength = 5, double gapLength = 5}) {
    final distance = (end - start).distance;
    final normalizedDirection = Offset(
      (end.dx - start.dx) / distance,
      (end.dy - start.dy) / distance,
    );

    double currentDistance = 0;
    bool isDash = true;

    while (currentDistance < distance) {
      final segmentLength = isDash ? dashLength : gapLength;
      final nextDistance = math.min(currentDistance + segmentLength, distance);
      
      if (isDash) {
        final segmentStart = Offset(
          start.dx + normalizedDirection.dx * currentDistance,
          start.dy + normalizedDirection.dy * currentDistance,
        );
        final segmentEnd = Offset(
          start.dx + normalizedDirection.dx * nextDistance,
          start.dy + normalizedDirection.dy * nextDistance,
        );
        canvas.drawLine(segmentStart, segmentEnd, paint);
      }
      
      currentDistance = nextDistance;
      isDash = !isDash;
    }
  }

  @override
  bool shouldRepaint(EdgesPainter oldDelegate) {
    return oldDelegate.nodes != nodes ||
        oldDelegate.edges != edges ||
        oldDelegate.connectionMode != connectionMode ||
        oldDelegate.connectionSource != connectionSource ||
        oldDelegate.mousePosition != mousePosition;
  }
}

extension ColorsExtension on Colors {
  static MaterialColor get slate => MaterialColor(
    0xFF64748B,
    <int, Color>{
      50: const Color(0xFFF8FAFC),
      100: const Color(0xFFF1F5F9),
      200: const Color(0xFFE2E8F0),
      300: const Color(0xFFCBD5E1),
      400: const Color(0xFF94A3B8),
      500: const Color(0xFF64748B),
      600: const Color(0xFF475569),
      700: const Color(0xFF334155),
      800: const Color(0xFF1E293B),
      900: const Color(0xFF0F172A),
    },
  );
}
