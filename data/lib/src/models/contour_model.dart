import 'package:domain/domain.dart';

import '../constants/request_constants.dart';

/// Data transfer object for a contour.
class ContourModel {
  /// Contour unique identifier.
  final String id;

  /// Contour title.
  final String title;

  /// Contour categories.
  final List<ContourCategory> categories;

  /// URL to the SVG file describing the contour.
  final String svgUrl;

  /// Preview image URL.
  final String previewUrl;

  /// Creation timestamp.
  final DateTime? createdAt;

  /// Raw monetization access type, for example `paid`.
  ///
  /// Kept as a string so unknown server values survive parsing; the mapping to
  /// [ContourAccessType] happens in the mapper.
  final String accessType;

  /// Price in cents for paid projects, `null` otherwise.
  final int? price;

  /// Explicit store product identifier for paid projects, `null` otherwise.
  final String? productId;

  /// Primary category getter kept for backwards compatibility.
  ContourCategory get category =>
      categories.isNotEmpty ? categories.first : ContourCategory.all;

  /// Creates a [ContourModel].
  const ContourModel({
    required this.id,
    required this.title,
    required this.categories,
    required this.svgUrl,
    required this.previewUrl,
    this.createdAt,
    this.accessType = RequestConstants.defaultContourAccessType,
    this.price,
    this.productId,
  });

  /// Creates a [ContourModel] from a JSON map.
  factory ContourModel.fromJson(Map<String, dynamic> json) {
    return ContourModel(
      id: json['id'] as String,
      title: json['title'] as String,
      categories: _parseCategories(json),
      svgUrl: json['svg_data'] as String,
      previewUrl: json['preview_url'] as String,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      accessType:
          json[RequestConstants.accessTypeColumn] as String? ??
          RequestConstants.defaultContourAccessType,
      price: json[RequestConstants.priceColumn] as int?,
      productId: json[RequestConstants.productIdColumn] as String?,
    );
  }

  /// Reads the `categories` array, falling back to the legacy `category`.
  ///
  /// Unknown values are skipped, and an empty result falls back to
  /// [ContourCategory.all] so the UI always has a value to work with.
  static List<ContourCategory> _parseCategories(Map<String, dynamic> json) {
    final Set<ContourCategory> categories = <ContourCategory>{};

    final dynamic rawCategories = json[RequestConstants.categoriesColumn];
    if (rawCategories is List) {
      for (final dynamic item in rawCategories) {
        if (item is String) {
          final ContourCategory? category = ContourCategory.tryParse(item);
          if (category != null) {
            categories.add(category);
          }
        }
      }
    }

    if (categories.isEmpty) {
      final dynamic legacyCategory = json[RequestConstants.categoryColumn];
      if (legacyCategory is String) {
        final ContourCategory? category = ContourCategory.tryParse(
          legacyCategory,
        );
        if (category != null) {
          categories.add(category);
        }
      }
    }

    if (categories.isEmpty) {
      categories.add(ContourCategory.all);
    }

    return categories.toList();
  }

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      RequestConstants.categoryColumn: category.name,
      RequestConstants.categoriesColumn: categories
          .map((ContourCategory c) => c.name)
          .toList(),
      'svg_data': svgUrl,
      'preview_url': previewUrl,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      RequestConstants.accessTypeColumn: accessType,
      RequestConstants.priceColumn: price,
      RequestConstants.productIdColumn: productId,
    };
  }
}
