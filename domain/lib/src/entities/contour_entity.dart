import 'package:equatable/equatable.dart';

import 'contour_category.dart';

/// Domain entity representing a coloring contour.
class ContourEntity extends Equatable {
  /// Unique contour identifier.
  final String id;

  /// Contour title.
  final String title;

  /// Contour category.
  final ContourCategory category;

  /// SVG data describing the contour shape.
  final String svgData;

  /// URL to the contour preview image.
  final String previewUrl;

  /// Creation timestamp.
  final DateTime? createdAt;

  /// Creates a [ContourEntity].
  const ContourEntity({
    required this.id,
    required this.title,
    required this.category,
    required this.svgData,
    required this.previewUrl,
    this.createdAt,
  });

  @override
  List<Object?> get props =>
      <Object?>[id, title, category, svgData, previewUrl, createdAt];
}
