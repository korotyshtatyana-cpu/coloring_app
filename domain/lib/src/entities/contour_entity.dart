import 'package:equatable/equatable.dart';

import 'contour_access_type.dart';
import 'contour_category.dart';

/// Domain entity representing a coloring contour.
class ContourEntity extends Equatable {
  /// Unique contour identifier.
  final String id;

  /// Contour title.
  final String title;

  /// Contour categories.
  final List<ContourCategory> categories;

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

  /// Primary category getter kept for backwards compatibility.
  ContourCategory get category =>
      categories.isNotEmpty ? categories.first : ContourCategory.all;

  /// Whether this contour belongs to [target].
  ///
  /// A contour can belong to several categories, so callers must use this
  /// check instead of comparing a single category value.
  bool hasCategory(ContourCategory target) => categories.contains(target);

  /// Creates a [ContourEntity].
  const ContourEntity({
    required this.id,
    required this.title,
    required this.categories,
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
    categories,
    svgUrl,
    previewUrl,
    createdAt,
    accessType,
    price,
    productId,
  ];
}
