import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../entities/stroke_entity.dart';

/// Builds the filled silhouette of a pressure-sensitive soft stroke.
///
/// Drawing each variable-width segment separately and blurring it produces a
/// visibly denser edge where consecutive blurs overlap. A soft brush is
/// therefore rendered as one silhouette: a round tip at every point plus a
/// quad between consecutive tips. The painters blur that single path once,
/// which keeps the line smooth and continuous.
abstract final class SoftBrushPath {
  /// Builds the complete silhouette for [stroke].
  static Path build(StrokeEntity stroke) {
    final Path path = Path()..fillType = PathFillType.nonZero;
    if (stroke.points.isEmpty) {
      return path;
    }

    final List<StrokePoint> points = stroke.points;
    addTip(path, points.first, stroke.size);
    for (int i = 0; i < points.length - 1; i++) {
      addSegment(path, points[i], points[i + 1], stroke.size);
      addTip(path, points[i + 1], stroke.size);
    }
    return path;
  }

  /// Creates a silhouette that starts with the tip at [point].
  ///
  /// Call [addSegment] and [addTip] as new points arrive to extend the same
  /// path incrementally while the user is drawing.
  static Path start(StrokePoint point, double size) {
    final Path path = Path()..fillType = PathFillType.nonZero;
    addTip(path, point, size);
    return path;
  }

  /// Adds a round tip for [point] to [path].
  static void addTip(Path path, StrokePoint point, double size) {
    final double radius = _radius(point.pressure, size);
    path.addOval(Rect.fromCircle(center: point.offset, radius: radius));
  }

  /// Adds the connecting quad between two consecutive tips to [path].
  ///
  /// The points are ordered clockwise, matching [Path.addOval], so the
  /// non-zero fill rule unions the overlapping subpaths instead of cancelling
  /// them.
  static void addSegment(
    Path path,
    StrokePoint from,
    StrokePoint to,
    double size,
  ) {
    final double dx = to.offset.dx - from.offset.dx;
    final double dy = to.offset.dy - from.offset.dy;
    final double length = math.sqrt(dx * dx + dy * dy);
    if (length == 0) {
      return;
    }

    final double nx = -dy / length;
    final double ny = dx / length;
    final double fromRadius = _radius(from.pressure, size);
    final double toRadius = _radius(to.pressure, size);

    path.addPolygon(<Offset>[
      from.offset - Offset(nx * fromRadius, ny * fromRadius),
      to.offset - Offset(nx * toRadius, ny * toRadius),
      to.offset + Offset(nx * toRadius, ny * toRadius),
      from.offset + Offset(nx * fromRadius, ny * fromRadius),
    ], true);
  }

  /// Radius of the silhouette at [pressure].
  ///
  /// Mirrors the hard brushes: `size * pressure / 2` with no upper bound. Some
  /// panels report values above 1.0 for a firm finger press, and the hard
  /// brushes (and the brush cursor) draw wider then, so the soft silhouette
  /// must widen with them instead of freezing at the brush size.
  static double _radius(double pressure, double size) {
    final double clamped = math.max(0, pressure);
    return math.max(0.5, size * clamped / 2);
  }
}
