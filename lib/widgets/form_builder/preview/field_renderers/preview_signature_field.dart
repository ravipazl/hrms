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

  @override
  void initState() {
    super.initState();
    if (widget.value != null && widget.value.toString().isNotEmpty) {
      isSigned = true;
    }
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
          child: Column(
            children: [
              GestureDetector(
                onPanStart: (details) {
                  setState(() {
                    points.add(details.localPosition);
                    isSigned = true;
                  });
                },
                onPanUpdate: (details) {
                  setState(() {
                    points.add(details.localPosition);
                  });
                },
                onPanEnd: (details) async {
                  setState(() {
                    points.add(null);
                  });
                  // Convert signature to base64 image
                  await _saveSignatureAsBase64();
                },
                child: CustomPaint(
                  painter: SignaturePainter(
                    points: points,
                    penColor: _hexToColor(penColor),
                  ),
                  size: const Size(double.infinity, 200),
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

  Future<void> _saveSignatureAsBase64() async {
    try {
      // Create a PictureRecorder to capture the signature
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      // Set background color
      final backgroundColor = widget.field.props['backgroundColor'] as String? ?? '#ffffff';
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, 400, 200),
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
      final img = await picture.toImage(400, 200);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        // Convert to base64
        final bytes = byteData.buffer.asUint8List();
        final base64String = base64Encode(bytes);
        final dataUrl = 'data:image/png;base64,$base64String';
        
        // Send to form
        widget.onChanged(dataUrl);
        debugPrint('✅ Signature converted to base64 (${bytes.length} bytes)');
      }
    } catch (e) {
      debugPrint('❌ Error converting signature: $e');
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

/// Custom painter for signature
class SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  final Color penColor;

  SignaturePainter({required this.points, required this.penColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = penColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
