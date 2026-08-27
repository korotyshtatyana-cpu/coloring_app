import 'dart:math';

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart' show PictureInfo;

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

/// CustomPainter that renders the contour SVG as vector graphics, tinted
/// with [color] at [opacity].
///
/// Unlike `SvgPicture` (which pre-rasterizes the SVG to a bitmap of the
/// intrinsic size), drawing the compiled picture directly keeps the contour
/// smooth at any zoom level.
class ContourPainter extends CustomPainter {
  /// Compiled SVG picture to draw.
  final PictureInfo pictureInfo;

  /// Tint color applied to the whole contour.
  final Color color;

  /// Contour opacity.
  final double opacity;

  /// Creates a [ContourPainter].
  ContourPainter({
    required this.pictureInfo,
    required this.color,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Size svgSize = pictureInfo.size;
    final double scale = min(
      size.width / svgSize.width,
      size.height / svgSize.height,
    );
    final double dx = (size.width - svgSize.width * scale) / 2;
    final double dy = (size.height - svgSize.height * scale) / 2;

    final Paint layerPaint = Paint()
      ..colorFilter = ColorFilter.mode(
        color.withValues(alpha: opacity),
        BlendMode.srcIn,
      );

    canvas.saveLayer(Offset.zero & size, layerPaint);
    canvas.translate(dx, dy);
    canvas.scale(scale);
    canvas.drawPicture(pictureInfo.picture);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ContourPainter oldDelegate) {
    return oldDelegate.pictureInfo != pictureInfo ||
        oldDelegate.color != color ||
        oldDelegate.opacity != opacity;
  }
}
