import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';

/// Position and size of the brush cursor shown while the user is drawing.
///
/// This is a [ChangeNotifier] on purpose: pointer events arrive up to 120 times
/// per second, and routing them through the BLoC would rebuild the whole canvas
/// tree on every move. The cursor layer listens to this notifier and repaints
/// only its own boundary instead.
///
/// For pressure-sensitive tools the visible diameter follows the stylus
/// pressure, exactly like the width of the stroke being drawn. For the rest of
/// the tools it stays equal to the brush size.
class BrushCursorController extends ChangeNotifier {
  Offset? _position;
  double _brushSize = 1;
  bool _pressureSensitive = false;
  double _diameter = 1;
  double _sceneScale = 1;

  /// Centre of the cursor in canvas (scene) coordinates.
  ///
  /// `null` means the cursor is hidden.
  Offset? get position => _position;

  /// Current diameter of the cursor in canvas units.
  ///
  /// Matches the brush size for constant-width tools and `brushSize * pressure`
  /// for pressure-sensitive ones.
  double get diameter => _diameter;

  /// Scale that maps canvas units to screen pixels.
  ///
  /// The painter divides its outline width by this value, so the ring keeps a
  /// constant thickness on screen at any zoom level.
  double get sceneScale => _sceneScale;

  /// Whether the cursor is currently visible.
  bool get isVisible => _position != null;

  /// Shows the cursor at [position] for a brush of [brushSize].
  ///
  /// When [pressureSensitive] is true the diameter is scaled by [pressure], so
  /// the ring always covers the same width as the stroke. [sceneScale] is the
  /// current canvas scale; it keeps the outline readable when zoomed out.
  void show({
    required Offset position,
    required double brushSize,
    required bool pressureSensitive,
    required double sceneScale,
    double pressure = 1,
  }) {
    _position = position;
    _brushSize = brushSize > 0 ? brushSize : 1;
    _pressureSensitive = pressureSensitive;
    _sceneScale = sceneScale > 0 ? sceneScale : 1;
    _diameter = _diameterFor(pressure);
    notifyListeners();
  }

  /// Moves the visible cursor to [position] and updates its size.
  ///
  /// For pressure-sensitive tools a new [pressure] changes the diameter even
  /// when the position stays the same, which is what makes the ring follow the
  /// tapering stroke. Does nothing when the cursor is hidden, so a stray move
  /// event cannot bring it back after the pointer was lifted.
  void move(Offset position, {double pressure = 1}) {
    if (_position == null) {
      return;
    }

    final double diameter = _diameterFor(pressure);
    if (_position == position && _diameter == diameter) {
      return;
    }

    _position = position;
    _diameter = diameter;
    notifyListeners();
  }

  /// Hides the cursor.
  ///
  /// The next frame paints nothing, so the circle disappears as soon as the
  /// pointer is lifted.
  void hide() {
    if (_position == null) {
      return;
    }
    _position = null;
    notifyListeners();
  }

  double _diameterFor(double pressure) {
    // Mirror the stroke width exactly: `StrokeRenderer` uses raw
    // `size * pressure` with no upper bound, and some panels report values
    // above 1.0 for a firm finger press. Clamping here made the ring freeze at
    // the brush size while the line kept growing.
    final double diameter = _pressureSensitive
        ? _brushSize * math.max(0, pressure)
        : _brushSize;
    // A ring smaller than one canvas unit would be invisible; the stroke
    // itself has no visible width at zero pressure either.
    return diameter > 0 ? diameter : 1;
  }
}
