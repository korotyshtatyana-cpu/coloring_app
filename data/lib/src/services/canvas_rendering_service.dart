import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:domain/domain.dart';
import 'package:core/core.dart';

/// Service responsible for rendering the canvas to an image.
abstract final class CanvasRenderingService {
  /// Renders the whole canvas (white background, strokes and contour) into
  /// PNG bytes with the longest side equal to [targetSize].
  static Future<ByteData?> renderCanvasPng({
    required String contourSvg,
    required Color contourColor,
    required double contourOpacity,
    required double contourWidth,
    required List<StrokeEntity> strokes,
    required double targetSize,
  }) async {
    // Strokes live in canvas (viewBox) coordinates; scale them to fit the
    // output while keeping the canvas aspect ratio.
    final Size canvasSize = SvgUtils.parseViewBoxSize(contourSvg) ??
        Size(targetSize, targetSize);
    final double scale = min(
      targetSize / canvasSize.width,
      targetSize / canvasSize.height,
    );
    final Size outputSize = Size(
      canvasSize.width * scale,
      canvasSize.height * scale,
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final backgroundPaint = Paint()..color = Colors.white;
    canvas.drawRect(Offset.zero & outputSize, backgroundPaint);
    canvas.scale(scale);

    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }

    await _drawContour(
      canvas,
      svgData: SvgUtils.applyStrokeWidth(contourSvg, contourWidth),
      color: contourColor,
      opacity: contourOpacity,
      width: contourWidth,
      size: canvasSize,
    );

    final picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(
      outputSize.width.round(),
      outputSize.height.round(),
    );
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    image.dispose();
    return byteData;
  }

  static void _drawStroke(Canvas canvas, StrokeEntity stroke) {
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

  static Future<void> _drawContour(
    Canvas canvas, {
    required String svgData,
    required Color color,
    required double opacity,
    required double width,
    required Size size,
  }) async {
    final PictureInfo pictureInfo = await vg.loadPicture(
      SvgStringLoader(svgData),
      null,
    );

    final recorder = ui.PictureRecorder();
    final strokeCanvas = Canvas(recorder);

    strokeCanvas.drawPicture(pictureInfo.picture);

    final strokePicture = recorder.endRecording();
    final layerPaint = Paint()
      ..colorFilter = ColorFilter.mode(
        color.withValues(alpha: opacity),
        BlendMode.srcIn,
      );

    canvas.saveLayer(Offset.zero & size, layerPaint);
    canvas.drawPicture(strokePicture);
    canvas.restore();

    pictureInfo.picture.dispose();
  }
}
