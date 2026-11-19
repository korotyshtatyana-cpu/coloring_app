import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'brush_cursor_controller.dart';

/// Paints the brush cursor as a two-tone ring in canvas coordinates.
///
/// The ring sits on top of the artwork, so it combines an opaque dark outer
/// edge with a white inner edge: at least one of them stays visible on any
/// paint colour underneath. The inside of the circle is left empty, so the
/// user can still see the canvas while drawing.
class BrushCursorPainter extends CustomPainter {
  /// Width of the dark outer edge, in screen pixels.
  static const double _outerStroke = 3;

  /// Fraction of the outer edge covered by the white inner edge.
  static const double _innerRatio = 0.45;

  /// Dark outer edge. Slightly transparent so the artwork shows through.
  static const Color _outerColor = Color(0xCC000000);

  /// White inner edge, visible over dark paint.
  static const Color _innerColor = Colors.white;

  /// Cursor state to paint.
  final BrushCursorController cursor;

  /// Creates a [BrushCursorPainter] that repaints when [cursor] changes.
  BrushCursorPainter({required this.cursor}) : super(repaint: cursor);

  @override
  void paint(Canvas canvas, Size size) {
    final Offset? position = cursor.position;
    if (position == null) {
      return;
    }

    final double radius = cursor.diameter / 2;
    final double scale = cursor.sceneScale;
    // The edge is specified in screen pixels, so it is converted back to canvas
    // units. It never grows wider than the circle, which keeps tiny brushes
    // round instead of turning them into a filled dot.
    final double outerWidth = math.min(_outerStroke / scale, radius * 0.6);
    final double innerWidth = outerWidth * _innerRatio;

    canvas
      ..drawCircle(position, radius, _strokePaint(outerWidth, _outerColor))
      ..drawCircle(position, radius, _strokePaint(innerWidth, _innerColor));
  }

  Paint _strokePaint(double width, Color color) {
    return Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..color = color;
  }

  @override
  bool shouldRepaint(covariant BrushCursorPainter oldDelegate) {
    return oldDelegate.cursor != cursor;
  }
}
