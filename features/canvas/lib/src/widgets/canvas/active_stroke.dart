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

  /// Cached path for non-pressure and soft pressure strokes.
  ///
  /// Soft pressure strokes use a filled silhouette so consecutive blurred
  /// segments do not create darker joints. Other pressure-sensitive strokes
  /// render segment-by-segment (variable width), so a single uniform-width path
  /// cannot be used and [path] stays `null` for them.
  Path? _path;

  /// Whether [_path] is a soft silhouette built by [SoftBrushPath].
  bool _usesSoftSilhouette = false;

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
    final first = stroke.points.first;
    _usesSoftSilhouette = stroke.brushType.isSoft && stroke.isPressureSensitive;
    if (_usesSoftSilhouette) {
      _path = SoftBrushPath.start(first, stroke.size);
    } else if (stroke.isPressureSensitive) {
      _path = null;
    } else {
      _path = Path()..moveTo(first.offset.dx, first.offset.dy);
    }
    _rawBounds = Rect.fromLTRB(
      first.offset.dx,
      first.offset.dy,
      first.offset.dx,
      first.offset.dy,
    );
    notifyListeners();
  }

  /// Appends a point to the active stroke, extending the cached path and
  /// bounds incrementally.
  void add(StrokePoint point) {
    if (_stroke == null) return;
    final StrokePoint? previous = _stroke!.points.isEmpty
        ? null
        : _stroke!.points.last;
    _stroke!.points.add(point);
    final Offset o = point.offset;
    if (_usesSoftSilhouette && previous != null) {
      SoftBrushPath.addSegment(_path!, previous, point, _stroke!.size);
      SoftBrushPath.addTip(_path!, point, _stroke!.size);
    } else {
      _path?.lineTo(o.dx, o.dy);
    }
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
    _usesSoftSilhouette = false;
    _rawBounds = null;
    notifyListeners();
  }
}
