import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../models/form_builder/form_field.dart' as form_models;
import '../../../../services/form_builder_api_service.dart';
import '../../../../services/auth_service.dart';

/// Preview Signature Field - Uploads signature to server
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
  bool _isUploading = false;
  String? _uploadError;
  String? _uploadedFilename;

  @override
  void initState() {
    super.initState();
    if (widget.value != null && widget.value.toString().isNotEmpty) {
      isSigned = true;
      _uploadedFilename = widget.value.toString();
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
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: (_uploadError != null || widget.hasError) ? Colors.red : Colors.grey[300]!,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
                color: _hexToColor(backgroundColor),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Column(
                  children: [
                    // Signature drawing area
                    SizedBox(
                      width: double.infinity,
                      height: 200,
                      child: GestureDetector(
                        onPanStart: (details) {
                          final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
                          if (renderBox == null) return;
                          
                          final localPosition = renderBox.globalToLocal(details.globalPosition);
                          
                          setState(() {
                            points.add(localPosition);
                            isSigned = true;
                            _uploadError = null;
                          });
                        },
                        onPanUpdate: (details) {
                          final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
                          if (renderBox == null) return;
                          
                          final localPosition = renderBox.globalToLocal(details.globalPosition);
                          
                          if (localPosition.dx >= 0 && localPosition.dx <= renderBox.size.width &&
                              localPosition.dy >= 0 && localPosition.dy <= 200) {
                            points.add(localPosition);
                            
                            if (points.length % 3 == 0 && mounted) {
                              setState(() {});
                            }
                          }
                        },
                        onPanEnd: (details) async {
                          setState(() {
                            points.add(null); // Separate strokes
                          });
                          
                          // Upload signature to server
                          await Future.delayed(const Duration(milliseconds: 100));
                          
                          if (mounted) {
                            await _uploadSignature();
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
                          Expanded(
                            child: Text(
                              isSigned ? 'Signed ✓' : 'Sign above',
                              style: TextStyle(
                                fontSize: 12,
                                color: isSigned ? Colors.green[700] : Colors.grey[600],
                                fontWeight: isSigned ? FontWeight.w600 : FontWeight.normal,
                              ),
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
            
            // Loading overlay when uploading
            if (_isUploading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
          ],
        ),
        
        // Error or Success message
        if (_uploadError != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 16, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _uploadError!,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _clearSignature() {
    setState(() {
      points.clear();
      isSigned = false;
      _uploadedFilename = null;
      _uploadError = null;
    });
    widget.onChanged('');
  }

  Future<void> _uploadSignature() async {
    if (_isUploading) {
      debugPrint('⚠️ Upload already in progress');
      return;
    }
    
    setState(() {
      _isUploading = true;
      _uploadError = null;
    });
    
    try {
      // Convert signature to PNG
      final pngBytes = await _convertToPng();
      if (pngBytes == null) {
        throw Exception('Failed to convert signature to PNG');
      }
      
      debugPrint('📤 Uploading signature...');
      debugPrint('✅ Signature bytes: ${pngBytes.length} bytes');
      
      // Get API service
      final authService = Provider.of<AuthService>(context, listen: false);
      final apiService = FormBuilderAPIService(authService);
      
      // Upload to server using the service method
      final filename = await apiService.uploadSignature(pngBytes, widget.field.id);
      
      debugPrint('✅ Upload successful! Filename: $filename');
      
      setState(() {
        _uploadedFilename = filename;
        _isUploading = false;
      });
      
      // Store filename in form data
      widget.onChanged(filename);
      
    } catch (e) {
      debugPrint('❌ Upload error: $e');
      setState(() {
        _isUploading = false;
        _uploadError = 'Failed to upload signature: ${e.toString()}';
      });
    }
  }

  Future<Uint8List?> _convertToPng() async {
    try {
      if (points.isEmpty || points.every((p) => p == null)) {
        debugPrint('⚠️ No signature points to convert');
        return null;
      }
      
      final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null) {
        debugPrint('❌ RenderBox is null');
        return null;
      }
      
      final canvasWidth = renderBox.size.width.toInt();
      final canvasHeight = 200;
      
      if (canvasWidth <= 0 || canvasHeight <= 0) {
        debugPrint('❌ Invalid canvas dimensions: ${canvasWidth}x${canvasHeight}');
        return null;
      }
      
      debugPrint('📐 Canvas size: ${canvasWidth}x${canvasHeight}');
      
      // Create picture recorder
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      // Draw background
      final backgroundColor = widget.field.props['backgroundColor'] as String? ?? '#ffffff';
      canvas.drawRect(
        Rect.fromLTWH(0, 0, canvasWidth.toDouble(), canvasHeight.toDouble()),
        Paint()..color = _hexToColor(backgroundColor),
      );
      
      // Draw signature
      final penColor = widget.field.props['penColor'] as String? ?? '#000000';
      final paint = Paint()
        ..color = _hexToColor(penColor)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;

      for (int i = 0; i < points.length - 1; i++) {
        if (points[i] != null && points[i + 1] != null) {
          canvas.drawLine(points[i]!, points[i + 1]!, paint);
        }
      }
      
      // Convert to image
      final picture = recorder.endRecording();
      final img = await picture.toImage(canvasWidth, canvasHeight);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        debugPrint('❌ Failed to convert to PNG bytes');
        return null;
      }
      
      return byteData.buffer.asUint8List();
      
    } catch (e) {
      debugPrint('❌ Error converting to PNG: $e');
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

/// Custom painter for signature
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

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) {
    return points.length != oldDelegate.points.length;
  }
}
