import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:domain/domain.dart';
import 'package:core/core.dart';

/// Watermark width as a fraction of the exported image width.
const double kWatermarkFraction = 0.25;

/// Inset from the right and bottom edges, as a fraction of the exported size.
const double kWatermarkMarginFraction = 0.02;

/// Asset path of the watermark PNG, relative to the `core_ui` package.
const String kWatermarkAssetPath = 'resources/images/watermark.png';

/// Blur sigma used by the legacy watercolor/airbrush brushes.
const double _legacyBlurSigma = 4;

/// Service responsible for rendering the canvas to an image.
abstract final class CanvasRenderingService {
  /// Renders the whole canvas (white background, strokes and contour) into
  /// PNG bytes with the longest side equal to [targetSize].
  static Future<ByteData?> renderCanvasPng({
    required String contourSvg,
    required Color contourColor,
    required double contourOpacity,
    required List<StrokeEntity> strokes,
    required double targetSize,
    Uint8List? watermarkBytes,
  }) async {
    // Strokes live in canvas (viewBox) coordinates; scale them to fit the
    // output while keeping the canvas aspect ratio.
    final Size rawSize = SvgUtils.parseViewBoxSize(contourSvg) ?? Size(targetSize, targetSize);
    final Size canvasSize = Size(rawSize.width * 1.5, rawSize.height * 1.5);
    final double scale = min(targetSize / canvasSize.width, targetSize / canvasSize.height);
    final Size outputSize = Size(canvasSize.width * scale, canvasSize.height * scale);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final backgroundPaint = Paint()..color = Colors.white;
    canvas.drawRect(Offset.zero & outputSize, backgroundPaint);

    // Strokes and the contour live in canvas coordinates, so they are drawn
    // inside a scaled layer that is closed before the watermark is placed.
    canvas.save();
    canvas.scale(scale);
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }

    await _drawContour(
      canvas,
      svgData: contourSvg,
      color: contourColor,
      opacity: contourOpacity,
      size: canvasSize,
    );
    canvas.restore();

    final ui.Image? watermark = await _decodeWatermark(watermarkBytes);
    if (watermark != null) {
      _drawWatermark(canvas, watermark, outputSize);
      watermark.dispose();
    }

    final picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(
      outputSize.width.round(),
      outputSize.height.round(),
    );
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return byteData;
  }

  /// Decodes [bytes] into an image, returning null if absent or unreadable.
  ///
  /// A watermark that fails to load must not fail the whole export, so any
  /// error here yields null and the image is exported unwatermarked.
  static Future<ui.Image?> _decodeWatermark(Uint8List? bytes) async {
    if (bytes == null || bytes.isEmpty) return null;
    try {
      final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      final ui.ImageDescriptor descriptor = await ui.ImageDescriptor.encoded(buffer);
      final ui.Codec codec = await descriptor.instantiateCodec();
      final ui.FrameInfo frame = await codec.getNextFrame();
      final ui.Image image = frame.image;
      codec.dispose();
      descriptor.dispose();
      buffer.dispose();
      return image;
    } catch (e) {
      ErrorHandler.report(e, StackTrace.current);
      return null;
    }
  }

  /// Stamps the watermark into the bottom-right corner.
  ///
  /// Width is [kWatermarkFraction] of the exported width; the height follows
  /// the watermark's own aspect ratio so it is never distorted. It is inset by
  /// [kWatermarkMarginFraction] of the exported size on both axes to keep it off
  /// the very edge.
  static void _drawWatermark(Canvas canvas, ui.Image watermark, Size outputSize) {
    final double width = outputSize.width * kWatermarkFraction;
    final double height = width * watermark.height / watermark.width;
    final double marginX = outputSize.width * kWatermarkMarginFraction;
    final double marginY = outputSize.height * kWatermarkMarginFraction;
    final Rect dest = Rect.fromLTWH(
      outputSize.width - width - marginX,
      outputSize.height - height - marginY,
      width,
      height,
    );
    canvas.drawImageRect(
      watermark,
      Rect.fromLTWH(0, 0, watermark.width.toDouble(), watermark.height.toDouble()),
      dest,
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  static void _drawStroke(Canvas canvas, StrokeEntity stroke) {
    if (stroke.points.length < 2) return;

    // Soft strokes are single paths, so their opacity is folded into the paint
    // below: Impeller can drop saveLayer alpha when the content has a mask
    // filter. For multi-segment strokes the layer still prevents darker
    // overlaps at the joints.
    final bool isSoft = stroke.brushType.isSoft;
    final bool useLayer = stroke.opacity < 1.0 && !isSoft;
    if (useLayer) {
      // Draw the stroke at full opacity into a layer, then composite the
      // layer once with the stroke opacity. This avoids darker overlaps at
      // segment joints, so a semi-transparent stroke looks like a uniform
      // line instead of a chain of dots.
      canvas.saveLayer(
        null,
        Paint()..color = Colors.white.withValues(alpha: stroke.opacity),
      );
    }

    final Color baseColor = Color(stroke.color);
    final paint = Paint()
      ..color = isSoft
          ? baseColor.withValues(alpha: baseColor.a * stroke.opacity)
          : baseColor
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final double? sigma = _blurSigmaFor(stroke);
    if (sigma != null) {
      paint.maskFilter = MaskFilter.blur(BlurStyle.normal, sigma);
    }

    if (stroke.brushType.isSoft && stroke.isPressureSensitive) {
      // One silhouette keeps the exported soft line continuous: blurring
      // every segment separately would darken the joints.
      paint.style = PaintingStyle.fill;
      canvas.drawPath(SoftBrushPath.build(stroke), paint);
    } else if (stroke.brushType.isSoft) {
      paint.strokeWidth = stroke.size;
      canvas.drawPath(_strokePath(stroke), paint);
    } else {
      for (int i = 0; i < stroke.points.length - 1; i++) {
        final point = stroke.points[i];
        final next = stroke.points[i + 1];

        if (stroke.isPressureSensitive) {
          paint.strokeWidth = stroke.size * point.pressure;
        } else {
          paint.strokeWidth = stroke.size;
        }

        canvas.drawLine(point.offset, next.offset, paint);
      }
    }

    if (useLayer) {
      canvas.restore();
    }
  }

  static double? _blurSigmaFor(StrokeEntity stroke) {
    if (stroke.brushType.isSoft) {
      return BrushSoftness.sigmaFor(
        stroke.size,
        pressureSensitive: stroke.isPressureSensitive,
        pressure: BrushSoftness.effectivePressure(stroke),
      );
    }
    if (stroke.brushType == BrushType.watercolor ||
        stroke.brushType == BrushType.airbrush) {
      return _legacyBlurSigma;
    }
    return null;
  }

  static Path _strokePath(StrokeEntity stroke) {
    final Offset first = stroke.points.first.offset;
    final Path path = Path()..moveTo(first.dx, first.dy);
    for (int i = 1; i < stroke.points.length; i++) {
      final Offset point = stroke.points[i].offset;
      path.lineTo(point.dx, point.dy);
    }
    return path;
  }

  static Future<void> _drawContour(
    Canvas canvas, {
    required String svgData,
    required Color color,
    required double opacity,
    required Size size,
  }) async {
    final PictureInfo pictureInfo = await vg.loadPicture(SvgStringLoader(svgData), null);

    final Size svgSize = pictureInfo.size;
    final double scaleX = size.width / svgSize.width;
    final double scaleY = size.height / svgSize.height;

    final recorder = ui.PictureRecorder();
    final strokeCanvas = Canvas(recorder);

    strokeCanvas.scale(scaleX, scaleY);
    strokeCanvas.drawPicture(pictureInfo.picture);

    final strokePicture = recorder.endRecording();
    final layerPaint = Paint()
      ..colorFilter = ColorFilter.mode(color.withValues(alpha: opacity), BlendMode.srcIn);

    canvas.saveLayer(Offset.zero & size, layerPaint);
    canvas.drawPicture(strokePicture);
    canvas.restore();

    pictureInfo.picture.dispose();
  }
}
