import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../models/stroke_model.dart';

/// Maps between [StrokeModel] and [StrokeEntity].
abstract final class StrokeMapper {
  /// Converts a model to an entity.
  static StrokeEntity toEntity(StrokeModel model) {
    return StrokeEntity(
      points: model.points
          .map((List<double> pair) => Offset(pair[0], pair[1]))
          .toList(),
      color: model.color,
      size: model.size,
      opacity: model.opacity,
      brushType: model.brushType,
    );
  }

  /// Converts an entity to a model.
  static StrokeModel toModel(StrokeEntity entity, String projectId) {
    return StrokeModel(
      id: '${projectId}_${entity.hashCode}',
      projectId: projectId,
      points: entity.points
          .map((Offset offset) => <double>[offset.dx, offset.dy])
          .toList(),
      color: entity.color,
      size: entity.size,
      opacity: entity.opacity,
      brushType: entity.brushType,
    );
  }
}
