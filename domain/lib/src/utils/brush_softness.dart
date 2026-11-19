import 'dart:math' as math;

import '../entities/stroke_entity.dart';

/// Soft-edge parameters shared by every stroke renderer.
///
/// The values live in the domain layer so the canvas feature and the export
/// service use exactly the same blur radius for a given stroke. Painters
/// turn [sigmaFor] into a `MaskFilter.blur`; the rest of the app only needs the
/// numeric value.
abstract final class BrushSoftness {
  /// Blur sigma as a fraction of the brush size for constant-width soft
  /// brushes.
  ///
  /// These brushes keep the full brush width at any pressure, so the blur can
  /// grow with the whole brush size and the edge stays soft without eating the
  /// ink.
  static const double sigmaFactor = 0.42;

  /// Blur sigma as a fraction of the *current* stroke width for
  /// pressure-sensitive brushes.
  ///
  /// A soft liner's silhouette is `size * pressure` wide, so its blur has to
  /// follow that width: a firm press gets a wide soft edge, a light one keeps
  /// a narrow blur and a legible core. Taking a fixed fraction of the nominal
  /// brush size instead would smear a light-pressure line across a blur many
  /// times its width and erase it, especially at low opacity.
  ///
  /// Independent of [sigmaFactor] on purpose: the two brush families have
  /// different edge profiles, and changing one must not wash out the other.
  static const double pressureSigmaFactor = 0.25;

  /// Smallest sigma used for a soft brush.
  ///
  /// Without a floor a size-1 brush would have an almost invisible blur.
  static const double minSigma = 0.5;

  /// Largest sigma used for a soft brush.
  ///
  /// Caps the GPU cost of very large brushes. Reached onl y by wide strokes or
  /// unusually firm pressure; light strokes stay well below it.
  static const double maxSigma = 20.0;

  /// How many sigmas of bleed are included in stroke bounds.
  ///
  /// The visible falloff of a normal blur is effectively gone after three
  /// sigma, so this is enough to avoid clipping the soft edge.
  static const double marginInSigmas = 3.0;

  /// Returns the blur sigma for a soft brush of [size] logical pixels.
  ///
  /// For a pressure-sensitive brush the width that matters is the one the
  /// stroke actually has at [pressure], not the nominal brush size. Pass
  /// [effectivePressure] to get one sigma for a whole stored stroke.
  static double sigmaFor(
    double size, {
    bool pressureSensitive = false,
    double pressure = 1.0,
  }) {
    final double factor = pressureSensitive ? pressureSigmaFactor : sigmaFactor;
    final double width = pressureSensitive
        ? size * math.max(0, pressure)
        : size;
    return (width * factor).clamp(minSigma, maxSigma);
  }

  /// Returns the extra bounds needed around a soft stroke of [size].
  static double marginFor(
    double size, {
    bool pressureSensitive = false,
    double pressure = 1.0,
  }) {
    return sigmaFor(
      size,
      pressureSensitive: pressureSensitive,
      pressure: pressure,
    ) * marginInSigmas;
  }

  /// Mean stored pressure of [stroke], used to pick one blur radius for its
  /// single silhouette.
  ///
  /// Non-pressure-sensitive brushes keep a full-width edge regardless of the
  /// reported pressure, so they return 1.0. The value comes from saved stroke
  /// data, which makes the blur identical while drawing, after reload and in
  /// exported images on every device.
  static double effectivePressure(StrokeEntity stroke) {
    if (!stroke.isPressureSensitive || stroke.points.isEmpty) return 1.0;
    double sum = 0;
    for (final StrokePoint point in stroke.points) {
      sum += point.pressure;
    }
    return sum / stroke.points.length;
  }
}
