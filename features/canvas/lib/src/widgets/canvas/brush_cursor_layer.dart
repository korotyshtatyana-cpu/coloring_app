import 'package:flutter/material.dart';

import 'brush_cursor_controller.dart';
import 'brush_cursor_painter.dart';

/// Overlay that draws the brush cursor on top of the artwork.
///
/// The layer lives inside the canvas coordinate space, so the circle zooms and
/// pans together with the strokes and always covers exactly the brush size.
/// It is also wrapped in a [RepaintBoundary]: pointer moves repaint only this
/// layer, never the finished-stroke bitmap or the contour.
class BrushCursorLayer extends StatelessWidget {
  /// Cursor state to draw.
  final BrushCursorController controller;

  /// Creates a [BrushCursorLayer].
  const BrushCursorLayer({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: BrushCursorPainter(cursor: controller),
        willChange: true,
      ),
    );
  }
}
