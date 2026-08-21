import 'dart:math';
import 'dart:ui' as ui;

import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

/// Eyedropper overlay showing a magnified area around the picked position.
class EyedropperOverlay extends StatelessWidget {
  /// Current pointer position.
  final Offset position;

  /// Color currently previewed at the pointer position.
  final Color previewColor;

  /// Currently selected brush color shown on the bottom border half.
  final Color selectedColor;

  /// Captured canvas image used to render the magnified loupe.
  final ui.Image? image;

  /// Size of the loupe.
  final double size;

  /// Magnification level for the zoom zone.
  final double magnification;

  /// Creates an [EyedropperOverlay].
  const EyedropperOverlay({
    required this.position,
    required this.previewColor,
    required this.selectedColor,
    this.image,
    this.size = 100,
    this.magnification = 2.5,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final Size viewportSize = MediaQuery.sizeOf(context);

    return Positioned(
      left: position.dx - size / 2,
      top: position.dy - size,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primaryBg,
              ),
              child: ClipOval(
                child: image != null
                    ? CustomPaint(
                        painter: _EyedropperLoupePainter(
                          image: image!,
                          viewportPosition: position,
                          viewportSize: viewportSize,
                          magnification: magnification,
                        ),
                      )
                    : null,
              ),
            ),
              CustomPaint(
                painter: _EyedropperBorderPainter(
                  previewColor: previewColor,
                  selectedColor: selectedColor,
                  strokeWidth: 10,
                ),
              ),
            const Center(
              child: Icon(
                Icons.add,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paints the eyedropper border in two halves:
/// the upper half uses the preview color and the lower half uses the selected
/// brush color.
class _EyedropperBorderPainter extends CustomPainter {
  final Color previewColor;
  final Color selectedColor;
  final double strokeWidth;

  _EyedropperBorderPainter({
    required this.previewColor,
    required this.selectedColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // Upper half: preview color (180° -> 360°).
    paint.color = previewColor;
    canvas.drawArc(rect, pi, pi, false, paint);

    // Lower half: selected color (0° -> 180°).
    paint.color = selectedColor;
    canvas.drawArc(rect, 0, pi, false, paint);
  }

  @override
  bool shouldRepaint(covariant _EyedropperBorderPainter oldDelegate) {
    return oldDelegate.previewColor != previewColor ||
        oldDelegate.selectedColor != selectedColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Paints a magnified circular clipping of the captured canvas image.
class _EyedropperLoupePainter extends CustomPainter {
  final ui.Image image;
  final Offset viewportPosition;
  final Size viewportSize;
  final double magnification;

  _EyedropperLoupePainter({
    required this.image,
    required this.viewportPosition,
    required this.viewportSize,
    required this.magnification,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double pixelRatio = image.width / viewportSize.width;
    final double srcCenterX = viewportPosition.dx * pixelRatio;
    final double srcCenterY = viewportPosition.dy * pixelRatio;
    final double srcSize = size.width / magnification;
    final double halfSrc = srcSize / 2;

    final double srcLeft =
        (srcCenterX - halfSrc).clamp(0, image.width - srcSize);
    final double srcTop =
        (srcCenterY - halfSrc).clamp(0, image.height - srcSize);

    final Rect srcRect = Rect.fromLTWH(srcLeft, srcTop, srcSize, srcSize);
    final Rect dstRect = Offset.zero & size;

    canvas.drawImageRect(
      image,
      srcRect,
      dstRect,
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(covariant _EyedropperLoupePainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.viewportPosition != viewportPosition ||
        oldDelegate.viewportSize != viewportSize ||
        oldDelegate.magnification != magnification;
  }
}
