import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

/// CustomPainter that renders the user drawing layer.
///
/// The transformation (pan/zoom) is applied by the parent [InteractiveViewer],
/// so this painter draws strokes in scene coordinates without an extra matrix.
///
/// The stroke currently being drawn is already included in [strokes], so there
/// is no separate "active" rendering path and opacity stays consistent.
class CanvasPainter extends CustomPainter {
  /// All strokes, including the one currently being drawn.
  final List<StrokeEntity> strokes;

  /// Creates a [CanvasPainter].
  CanvasPainter({
    required this.strokes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);

    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }
  }

  void _drawBackground(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    canvas.drawRect(Offset.zero & size, paint);
  }

  void _drawStroke(Canvas canvas, StrokeEntity stroke) {
    if (stroke.points.length < 2) return;

    final paint = Paint()
      ..color = Color(stroke.color).withValues(alpha: stroke.opacity)
      ..strokeWidth = stroke.size
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (stroke.brushType == BrushType.watercolor ||
        stroke.brushType == BrushType.airbrush) {
      paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    }

    final path = Path();
    path.moveTo(stroke.points.first.dx, stroke.points.first.dy);
    for (int i = 1; i < stroke.points.length; i++) {
      path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CanvasPainter oldDelegate) {
    return oldDelegate.strokes != strokes;
  }
}
