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

  /// Extra space around stroke bounds for the mask-filter blur.
  /// The blur sigma is 4, and the visible bleed stays within ~3 sigma.
  static const double _blurMargin = 12;

  void _drawStroke(Canvas canvas, StrokeEntity stroke) {
    if (stroke.points.length < 2) return;

    final bool useLayer = stroke.opacity < 1.0;
    if (useLayer) {
      // Draw the stroke at full opacity into a layer, then composite the
      // layer once with the stroke opacity. This avoids darker overlaps at
      // segment joints, so a semi-transparent stroke looks like a uniform
      // line instead of a chain of dots.
      //
      // The layer is limited to the stroke bounds: null bounds would
      // allocate a full-canvas offscreen buffer per stroke, which makes
      // panning and zooming stutter when there are many strokes.
      canvas.saveLayer(
        _strokeBounds(stroke),
        Paint()..color = Colors.white.withValues(alpha: stroke.opacity),
      );
    }

    final paint = Paint()
      ..color = Color(stroke.color)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (stroke.brushType == BrushType.watercolor ||
        stroke.brushType == BrushType.airbrush) {
      paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    }

    if (stroke.isPressureSensitive) {
      _drawPressureStroke(canvas, stroke, paint);
    } else {
      // A single path is one draw call instead of a drawLine per segment;
      // round joins keep the corners smooth.
      paint.strokeWidth = stroke.size;
      canvas.drawPath(_strokePath(stroke), paint);
    }

    if (useLayer) {
      canvas.restore();
    }
  }

  Path _strokePath(StrokeEntity stroke) {
    final Offset first = stroke.points.first.offset;
    final Path path = Path()..moveTo(first.dx, first.dy);
    for (int i = 1; i < stroke.points.length; i++) {
      final Offset point = stroke.points[i].offset;
      path.lineTo(point.dx, point.dy);
    }
    return path;
  }

  void _drawPressureStroke(Canvas canvas, StrokeEntity stroke, Paint paint) {
    for (int i = 0; i < stroke.points.length - 1; i++) {
      final p1 = stroke.points[i];
      final p2 = stroke.points[i + 1];

      // Linear interpolation of width based on pressure at each point.
      final double w1 = stroke.size * p1.pressure;
      final double w2 = stroke.size * p2.pressure;
      paint.strokeWidth = (w1 + w2) / 2;

      canvas.drawLine(p1.offset, p2.offset, paint);
    }
  }

  /// Stroke bounds inflated enough to contain the round caps, pressure
  /// width and the blur, so the saveLayer clip never cuts the stroke.
  Rect _strokeBounds(StrokeEntity stroke) {
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;
    for (final StrokePoint point in stroke.points) {
      final Offset offset = point.offset;
      if (offset.dx < minX) minX = offset.dx;
      if (offset.dy < minY) minY = offset.dy;
      if (offset.dx > maxX) maxX = offset.dx;
      if (offset.dy > maxY) maxY = offset.dy;
    }
    // Round caps and pressure width can extend up to ~stroke.size beyond
    // the points, plus the blur needs a few extra pixels.
    final double margin = stroke.size + _blurMargin;
    return Rect.fromLTRB(
      minX - margin,
      minY - margin,
      maxX + margin,
      maxY + margin,
    );
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
