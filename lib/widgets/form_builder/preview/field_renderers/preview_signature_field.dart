import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../models/form_builder/form_field.dart' as form_models;

/// Preview Signature Field - Functional signature pad field
class PreviewSignatureField extends StatefulWidget {
  final form_models.FormField field;
  final dynamic value;
  final Function(dynamic) onChanged;
  final bool hasError;

  const PreviewSignatureField({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
    this.hasError = false,
  });
 
  @override
  State<PreviewSignatureField> createState() => _PreviewSignatureFieldState();
}

class _PreviewSignatureFieldState extends State<PreviewSignatureField> {
  List<Offset?> points = [];
  bool isSigned = false;
  bool _isDrawing = false;

  @override
  void initState() {
    super.initState();
    if (widget.value != null && widget.value.toString().isNotEmpty) {
      isSigned = true;
    }
  }
  
  // Call this to export signature when needed (e.g., on form submit)
  Future<String?> exportToBase64() async {
    if (points.isEmpty) return null;
    return await _saveSignatureAsBase64();
  }

  @override
  Widget build(BuildContext context) {
    final penColor = widget.field.props['penColor'] as String? ?? '#000000';
    final backgroundColor = widget.field.props['backgroundColor'] as String? ?? '#ffffff';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          children: [
            Text(
              widget.field.label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (widget.field.required)
              const Text(
                ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Signature Canvas
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: widget.hasError ? Colors.red : Colors.grey[300]!,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
            color: _hexToColor(backgroundColor),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Column(
              children: [
                // Signature drawing area with proper constraints
                SizedBox(
                  width: double.infinity,
                  height: 200,
                  child: GestureDetector(
                    onPanStart: (details) {
                      final RenderBox renderBox = context.findRenderObject() as RenderBox;
                      final localPosition = renderBox.globalToLocal(details.globalPosition);
                      
                      _isDrawing = true;
                      points.add(localPosition);
                      isSigned = true;
                      
                      // Schedule frame to update UI
                      if (mounted) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() {});
                        });
                      }
                    },
                    onPanUpdate: (details) {
                      if (!_isDrawing) return;
                      
                      final RenderBox renderBox = context.findRenderObject() as RenderBox;
                      final localPosition = renderBox.globalToLocal(details.globalPosition);
                      
                      // Only add point if it's within bounds
                      if (localPosition.dx >= 0 && localPosition.dx <= renderBox.size.width &&
                          localPosition.dy >= 0 && localPosition.dy <= 200) {
                        points.add(localPosition);
                        
                        // Batch updates - only setState every few points for smooth drawing
                        if (points.length % 3 == 0 && mounted) {
                          setState(() {});
                        }
                      }
                    },
                    onPanEnd: (details) async {
                      _isDrawing = false;
                      points.add(null);
                      
                      if (mounted) {
                        setState(() {});
                      }
                      
                      // Export signature as base64 and store it
                      final base64Data = await _saveSignatureAsBase64();
                      if (base64Data != null) {
                        widget.onChanged(base64Data);
                        debugPrint('✅ Signature exported: ${base64Data.length} chars');
                      }
                    },
                    child: CustomPaint(
                      painter: SignaturePainter(
                        points: points,
                        penColor: _hexToColor(penColor),
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ),

                // Actions Bar
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isSigned ? 'Signed' : 'Sign above',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _clearSignature,
                        icon: const Icon(Icons.clear, size: 16),
                        label: const Text('Clear'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.grey[700],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _clearSignature() {
    setState(() {
      points.clear();
      isSigned = false;
    });
    widget.onChanged('');
  }

  // Export signature to base64 - call this when needed (e.g., form submit)
  Future<String?> exportSignature() async {
    if (points.isEmpty) return null;
    return await _saveSignatureAsBase64();
  }

  Future<String?> _saveSignatureAsBase64() async {
    try {
      // Get the actual render box to determine canvas size
      final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null) return null;
      
      final canvasWidth = renderBox.size.width.toInt();
      final canvasHeight = 200;
      
      // Create a PictureRecorder to capture the signature
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      // Set background color
      final backgroundColor = widget.field.props['backgroundColor'] as String? ?? '#ffffff';
      canvas.drawRect(
        Rect.fromLTWH(0, 0, canvasWidth.toDouble(), canvasHeight.toDouble()),
        Paint()..color = _hexToColor(backgroundColor),
      );
      
      // Draw the signature
      final penColor = widget.field.props['penColor'] as String? ?? '#000000';
      final paint = Paint()
        ..color = _hexToColor(penColor)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < points.length - 1; i++) {
        if (points[i] != null && points[i + 1] != null) {
          canvas.drawLine(points[i]!, points[i + 1]!, paint);
        }
      }
      
      // Convert to image
      final picture = recorder.endRecording();
      final img = await picture.toImage(canvasWidth, canvasHeight);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        // Convert to base64
        final bytes = byteData.buffer.asUint8List();
        final base64String = base64Encode(bytes);
        final dataUrl = 'data:image/png;base64,$base64String';
        
        debugPrint('✅ Signature converted to base64 (${bytes.length} bytes)');
        return dataUrl;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error converting signature: $e');
      return null;
    }
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }
}

/// Custom painter for signature with optimized rendering
class SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  final Color penColor;

  SignaturePainter({required this.points, required this.penColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = penColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    // Draw lines between points efficiently
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) {
    // Only repaint if points actually changed
    return points.length != oldDelegate.points.length;
  }
}
