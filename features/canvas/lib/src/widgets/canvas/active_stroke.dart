import 'dart:math';

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

/// Mutable holder for the stroke currently being drawn.
///
/// Points are appended to the stroke's list in place (O(1) per pointer event)
/// while a cached [Path] (for non-pressure strokes) and the point bounds are
/// maintained incrementally. This avoids the O(n) list copies and full path
/// rebuilds per frame that made long strokes lag behind the pointer.
class ActiveStroke extends ChangeNotifier {
  StrokeEntity? _stroke;

  /// Cached path for non-pressure strokes. Pressure-sensitive strokes render
  /// segment-by-segment (variable width), so a single uniform-width path
  /// cannot be used; [path] stays `null` for them.
  Path? _path;

  /// Bounds of the raw points, maintained incrementally. Used for the
  /// `saveLayer` clip bounds of translucent strokes.
  Rect? _rawBounds;

  /// The stroke being drawn, or null when idle.
  StrokeEntity? get stroke => _stroke;

  /// Cached incremental path, or null for pressure-sensitive strokes.
  Path? get path => _path;

  /// Bounds of all points added so far.
  Rect? get rawBounds => _rawBounds;

  /// Starts a new stroke. The first point of the stroke seeds the path and
  /// the bounds.
  void begin(StrokeEntity stroke) {
    _stroke = stroke;
    final first = stroke.points.first.offset;
    if (stroke.isPressureSensitive) {
      _path = null;
    } else {
      _path = Path()..moveTo(first.dx, first.dy);
    }
    _rawBounds = Rect.fromLTRB(first.dx, first.dy, first.dx, first.dy);
    notifyListeners();
  }

  /// Appends a point to the active stroke, extending the cached path and
  /// bounds incrementally.
  void add(StrokePoint point) {
    if (_stroke == null) return;
    _stroke!.points.add(point);
    final Offset o = point.offset;
    _path?.lineTo(o.dx, o.dy);
    final Rect b = _rawBounds!;
    _rawBounds = Rect.fromLTRB(
      min(b.left, o.dx),
      min(b.top, o.dy),
      max(b.right, o.dx),
      max(b.bottom, o.dy),
    );
    notifyListeners();
  }

  /// Clears the active stroke (after finalize or cancel).
  void clear() {
    _stroke = null;
    _path = null;
    _rawBounds = null;
    notifyListeners();
  }
}
