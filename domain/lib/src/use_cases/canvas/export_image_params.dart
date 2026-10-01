import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../entities/stroke_entity.dart';

/// Parameters for exporting a project as an image.
class ExportImageParams {
  /// Project identifier (matches the contour id).
  final String projectId;

  /// SVG XML content of the contour to draw on top.
  final String contourSvg;

  /// Color applied to the contour.
  final Color contourColor;

  /// Opacity of the contour layer.
  final double contourOpacity;

  /// Explicit strokes to render. When null, strokes are loaded from storage.
  final List<StrokeEntity>? strokes;

  /// PNG bytes of the watermark to stamp on the exported image.
  ///
  /// Passed as bytes rather than an asset path so that this layer stays free of
  /// asset-bundle concerns. Null leaves the export unwatermarked.
  final Uint8List? watermarkBytes;

  /// Creates [ExportImageParams].
  const ExportImageParams({
    required this.projectId,
    required this.contourSvg,
    required this.contourColor,
    required this.contourOpacity,
    this.strokes,
    this.watermarkBytes,
  });
}
