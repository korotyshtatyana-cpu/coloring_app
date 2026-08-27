import 'package:flutter/material.dart';

import '../../entities/stroke_entity.dart';

/// Parameters for exporting a project as an image.
class ExportImageParams {
  /// Project identifier (matches the contour id).
  final String projectId;

  /// SVG data of the contour to draw on top.
  final String contourSvg;

  /// Color applied to the contour.
  final Color contourColor;

  /// Opacity of the contour layer.
  final double contourOpacity;

  /// Stroke width of the contour.
  final double contourWidth;

  /// Explicit strokes to render. When null, strokes are loaded from storage.
  final List<StrokeEntity>? strokes;

  /// Creates [ExportImageParams].
  const ExportImageParams({
    required this.projectId,
    required this.contourSvg,
    required this.contourColor,
    required this.contourOpacity,
    required this.contourWidth,
    this.strokes,
  });
}
