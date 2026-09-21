import 'dart:math';
import 'dart:ui' as ui;

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart' show PictureInfo;

/// Extra space around stroke bounds for the mask-filter blur.
/// The blur sigma is 4, and the visible bleed stays within ~3 sigma.
const double _blurMargin = 12;

/// Utility class to render strokes onto a [Canvas].
abstract final class StrokeRenderer {
  /// Renders a single [stroke] onto the given [canvas].
  static void drawStroke(Canvas canvas, StrokeEntity stroke) {
    if (stroke.points.length < 2) return;

    final bool useLayer = stroke.opacity < 1.0;
    if (useLayer) {
      // Draw the stroke at full opacity into a layer, then composite the
      // layer once with the stroke opacity.
      canvas.saveLayer(
        getStrokeBounds(stroke),
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

    final double? uniformWidth = _getUniformWidth(stroke);
    if (uniformWidth != null) {
      paint.strokeWidth = uniformWidth;
      canvas.drawPath(_getStrokePath(stroke), paint);
    } else {
      _drawPressureStroke(canvas, stroke, paint);
    }

    if (useLayer) {
      canvas.restore();
    }
  }

  static Path _getStrokePath(StrokeEntity stroke) {
    final Offset first = stroke.points.first.offset;
    final Path path = Path()..moveTo(first.dx, first.dy);
    for (int i = 1; i < stroke.points.length; i++) {
      final Offset point = stroke.points[i].offset;
      path.lineTo(point.dx, point.dy);
    }
    return path;
  }

  static double? _getUniformWidth(StrokeEntity stroke) {
    if (!stroke.isPressureSensitive) return stroke.size;
    final double first = stroke.points.first.pressure;
    for (final StrokePoint point in stroke.points) {
      if (point.pressure != first) return null;
    }
    return stroke.size * first;
  }

  static void _drawPressureStroke(Canvas canvas, StrokeEntity stroke, Paint paint) {
    for (int i = 0; i < stroke.points.length - 1; i++) {
      final p1 = stroke.points[i];
      final p2 = stroke.points[i + 1];

      final double w1 = stroke.size * p1.pressure;
      final double w2 = stroke.size * p2.pressure;
      paint.strokeWidth = (w1 + w2) / 2;

      canvas.drawLine(p1.offset, p2.offset, paint);
    }
  }

  /// Calculates visual bounds of the stroke.
  static Rect getStrokeBounds(StrokeEntity stroke) {
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
    final double margin = stroke.size + _blurMargin;
    return Rect.fromLTRB(
      minX - margin,
      minY - margin,
      maxX + margin,
      maxY + margin,
    );
  }
}

/// CustomPainter that renders a list of strokes.
class CanvasPainter extends CustomPainter {
  /// All strokes to draw.
  final List<StrokeEntity> strokes;

  /// Whether to draw a white background rectangle.
  final bool drawBackground;

  /// Creates a [CanvasPainter].
  CanvasPainter({required this.strokes, this.drawBackground = false});

  @override
  void paint(Canvas canvas, Size size) {
    if (drawBackground) {
      canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    }

    for (final stroke in strokes) {
      StrokeRenderer.drawStroke(canvas, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant CanvasPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.drawBackground != drawBackground;
  }
}

/// CustomPainter that renders a single [ui.Image] buffer.
class BitmapPainter extends CustomPainter {
  /// The image buffer to draw.
  final ui.Image image;

  /// Creates a [BitmapPainter].
  BitmapPainter({required this.image});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImage(image, Offset.zero, Paint());
  }

  @override
  bool shouldRepaint(covariant BitmapPainter oldDelegate) =>
      oldDelegate.image != image;
}

/// CustomPainter that renders the single stroke currently being drawn.
class ActiveStrokePainter extends CustomPainter {
  /// The stroke being drawn.
  final StrokeEntity stroke;

  /// Incrementally built path; `null` for pressure-sensitive strokes.
  final Path? cachedPath;

  /// Raw point bounds used to clip the opacity `saveLayer`.
  final Rect? rawBounds;

  /// Creates an [ActiveStrokePainter].
  ActiveStrokePainter({required this.stroke, this.cachedPath, this.rawBounds});

  @override
  void paint(Canvas canvas, Size size) {
    if (stroke.points.length < 2) return;

    final bool useLayer = stroke.opacity < 1.0;
    Rect? layerBounds = rawBounds;
    if (useLayer && layerBounds != null) {
      final double margin = stroke.size + _blurMargin;
      canvas.saveLayer(
        Rect.fromLTRB(
          layerBounds.left - margin,
          layerBounds.top - margin,
          layerBounds.right + margin,
          layerBounds.bottom + margin,
        ),
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

    final Path? path = cachedPath;
    if (stroke.isPressureSensitive || path == null) {
      // Variable-width strokes are drawn segment by segment.
      for (int i = 0; i < stroke.points.length - 1; i++) {
        final StrokePoint p1 = stroke.points[i];
        final StrokePoint p2 = stroke.points[i + 1];
        final double w1 = stroke.size * p1.pressure;
        final double w2 = stroke.size * p2.pressure;
        paint.strokeWidth = (w1 + w2) / 2;
        canvas.drawLine(p1.offset, p2.offset, paint);
      }
    } else {
      paint.strokeWidth = stroke.size;
      canvas.drawPath(path, paint);
    }

    if (useLayer && layerBounds != null) {
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ActiveStrokePainter oldDelegate) => true;
}

/// CustomPainter that renders the contour SVG as vector graphics.
class ContourPainter extends CustomPainter {
  final PictureInfo pictureInfo;
  final Color color;
  final double opacity;

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
