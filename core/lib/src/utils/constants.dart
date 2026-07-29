/// Application-wide constants.
abstract final class Constants {
  /// Maximum number of undo steps available on the canvas.
  static const int maxUndoSteps = 5;

  /// Maximum number of points per stroke.
  static const int maxStrokePoints = 1000;

  /// Number of items loaded per page in the gallery.
  static const int pageSize = 20;

  /// Default brush size in logical pixels.
  static const double defaultBrushSize = 10.0;

  /// Minimum brush size in logical pixels.
  static const double minBrushSize = 1.0;

  /// Maximum brush size in logical pixels.
  static const double maxBrushSize = 100.0;

  /// Default brush opacity (0.0 - 1.0).
  static const double defaultOpacity = 1.0;

  /// Default contour opacity (0.0 - 1.0).
  static const double contourDefaultOpacity = 1.0;

  /// Default contour stroke width.
  static const double contourDefaultWidth = 2.0;

  /// Minimum contour stroke width.
  static const double minContourWidth = 0.5;

  /// Maximum contour stroke width.
  static const double maxContourWidth = 10.0;

  /// Debounce duration for autosave after a stroke.
  static const Duration autosaveDebounce = Duration(milliseconds: 500);
}
