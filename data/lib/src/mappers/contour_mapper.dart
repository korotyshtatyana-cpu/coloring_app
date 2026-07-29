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
      svgData: model.svgData,
      previewUrl: model.previewUrl,
      createdAt: model.createdAt,
    );
  }

  /// Converts an entity to a model.
  static ContourModel toModel(ContourEntity entity) {
    return ContourModel(
      id: entity.id,
      title: entity.title,
      category: entity.category,
      svgData: entity.svgData,
      previewUrl: entity.previewUrl,
      createdAt: entity.createdAt,
    );
  }
}
