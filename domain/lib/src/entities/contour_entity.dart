import 'package:equatable/equatable.dart';

import 'contour_access_type.dart';
import 'contour_category.dart';

/// Domain entity representing a coloring contour.
class ContourEntity extends Equatable {
  /// Unique contour identifier.
  final String id;

  /// Contour title.
  final String title;

  /// Contour category.
  final ContourCategory category;

  /// URL to the SVG file describing the contour shape.
  final String svgUrl;

  /// URL to the contour preview image.
  final String previewUrl;

  /// Creation timestamp.
  final DateTime? createdAt;

  /// Monetization access type of the project.
  final ContourAccessType accessType;

  /// Price in cents for paid projects, `null` for every other access type.
  final int? price;

  /// Store product identifier used to buy the project individually.
  ///
  /// `null` for free and rewarded projects; when a paid project has no explicit
  /// identifier the data layer falls back to `contour_{id}`.
  final String? productId;

  /// Creates a [ContourEntity].
  const ContourEntity({
    required this.id,
    required this.title,
    required this.category,
    required this.svgUrl,
    required this.previewUrl,
    this.createdAt,
    this.accessType = ContourAccessType.free,
    this.price,
    this.productId,
  });

  @override
  List<Object?> get props => <Object?>[
    id,
    title,
    category,
    svgUrl,
    previewUrl,
    createdAt,
    accessType,
    price,
    productId,
  ];
}
