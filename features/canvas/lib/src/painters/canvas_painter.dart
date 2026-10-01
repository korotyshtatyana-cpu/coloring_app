import 'dart:ui' as ui;

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart' show PictureInfo;

import '../utils/perf_log.dart';

/// Extra space around stroke bounds for the mask-filter blur.
/// The blur sigma is 4, and the visible bleed stays within ~3 sigma.
const double _blurMargin = 12;

/// Utility class to render strokes onto a [Canvas].
abstract final class StrokeRenderer {
  /// Renders a single [stroke] onto the given [canvas].
  ///
  /// [visibleArea] is the page the stroke belongs to. A stroke may run outside
  /// of it while the finger is down, and that part is clipped away anyway, so
  /// it is used to keep the opacity layer down to the visible part instead of
  /// the whole off-page excursion.
  static void drawStroke(
    Canvas canvas,
    StrokeEntity stroke, {
    Rect? visibleArea,
  }) {
    if (stroke.points.length < 2) return;

    final bool useLayer = stroke.opacity < 1.0;
    if (useLayer) {
      final Rect bounds = getStrokeBounds(stroke);
      // Draw the stroke at full opacity into a layer, then composite the
      // layer once with the stroke opacity.
      canvas.saveLayer(
        visibleArea == null ? bounds : bounds.intersect(visibleArea),
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
      StrokeRenderer.drawStroke(
        canvas,
        stroke,
        visibleArea: Offset.zero & size,
      );
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
    perfCountPaint('bitmap(${image.width}x${image.height})');
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.medium,
    );
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
    perfCountPaint(
      'stroke(${stroke.brushType.name},op=${stroke.opacity},'
      'n=${stroke.points.length},pressure=${stroke.isPressureSensitive})',
    );

    final bool useLayer = stroke.opacity < 1.0;
    Rect? layerBounds = rawBounds;
    if (useLayer && layerBounds != null) {
      final double margin = stroke.size + _blurMargin;
      // The paint area is the page, so the layer is limited to the part of the
      // stroke the user can see: a stroke running outside of the page would
      // otherwise make the layer grow with the excursion.
      final Rect page = Offset.zero & size;
      canvas.saveLayer(
        Rect.fromLTRB(
          layerBounds.left - margin,
          layerBounds.top - margin,
          layerBounds.right + margin,
          layerBounds.bottom + margin,
        ).intersect(page),
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

  /// Pre-rasterized contour, preferred when available.
  ///
  /// Replaying thousands of vector paths costs over 100 ms per frame, and
  /// tinting them needs a page-sized `saveLayer`, so the cached raster is used
  /// instead.
  final ui.Image? rasterImage;

  final Color color;
  final double opacity;

  ContourPainter({
    required this.pictureInfo,
    this.rasterImage,
    required this.color,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final ui.Image? image = rasterImage;
    if (image != null) {
      perfCountPaint('contour-raster(${image.width}x${image.height})');
      // The tint rides on the paint of the draw call, so the filter is applied
      // to the pixels being drawn and no page-sized offscreen buffer is needed.
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Offset.zero & size,
        Paint()
          ..colorFilter = ColorFilter.mode(
            color.withValues(alpha: opacity),
            BlendMode.srcIn,
          ),
      );
      return;
    }

    perfCountPaint(
      'contour(size=${size.width.round()}x${size.height.round()},'
      'tint=${!_isIdentityTint})',
    );
    final Size svgSize = pictureInfo.size;
    final double scaleX = size.width / svgSize.width;
    final double scaleY = size.height / svgSize.height;

    // `ColorFilter.mode(white, srcIn)` at opacity 1 is a no-op, so the layer
    // can be skipped entirely. Drawing the picture directly avoids allocating a
    // page-sized offscreen buffer and running the filter over every path, which
    // dominates the repaint cost for contours with thousands of paths.
    if (_isIdentityTint) {
      canvas
        ..save()
        ..scale(scaleX, scaleY)
        ..drawPicture(pictureInfo.picture)
        ..restore();
      return;
    }

    final Paint layerPaint = Paint()
      ..colorFilter = ColorFilter.mode(
        color.withValues(alpha: opacity),
        BlendMode.srcIn,
      );

    canvas.saveLayer(Offset.zero & size, layerPaint);
    canvas.scale(scaleX, scaleY);
    canvas.drawPicture(pictureInfo.picture);
    canvas.restore();
  }

  /// Whether the color filter leaves the vector unchanged.
  bool get _isIdentityTint =>
      color.r == 1 && color.g == 1 && color.b == 1 && opacity == 1;

  @override
  bool shouldRepaint(covariant ContourPainter oldDelegate) {
    return oldDelegate.pictureInfo != pictureInfo ||
        oldDelegate.rasterImage != rasterImage ||
        oldDelegate.color != color ||
        oldDelegate.opacity != opacity;
  }
}
