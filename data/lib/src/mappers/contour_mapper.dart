import 'package:domain/domain.dart';

import '../models/contour_model.dart';

/// Maps between [ContourModel] and [ContourEntity].
abstract final class ContourMapper {
  /// Converts a model to an entity.
  static ContourEntity toEntity(ContourModel model) {
    return ContourEntity(
      id: model.id,
      title: model.title,
      category: model.category,
      svgUrl: model.svgUrl,
      previewUrl: model.previewUrl,
      createdAt: model.createdAt,
      accessType: _toAccessType(model.accessType),
      price: model.price,
      productId: model.productId,
    );
  }

  /// Converts an entity to a model.
  static ContourModel toModel(ContourEntity entity) {
    return ContourModel(
      id: entity.id,
      title: entity.title,
      category: entity.category,
      svgUrl: entity.svgUrl,
      previewUrl: entity.previewUrl,
      createdAt: entity.createdAt,
      accessType: entity.accessType.dbValue,
      price: entity.price,
      productId: entity.productId,
    );
  }

  /// Maps the raw access type string to [ContourAccessType].
  ///
  /// Unknown values fall back to [ContourAccessType.free] so an unexpected
  /// server value never locks a project the user already paid for.
  static ContourAccessType _toAccessType(String value) {
    return switch (value) {
      'free' => ContourAccessType.free,
      'rewarded' => ContourAccessType.rewarded,
      'paid' => ContourAccessType.paid,
      _ => ContourAccessType.free,
    };
  }
}
