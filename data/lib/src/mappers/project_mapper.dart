import 'package:domain/domain.dart';

import '../models/project_model.dart';

/// Maps between [ProjectModel] and [ProjectEntity].
abstract final class ProjectMapper {
  /// Converts a model to an entity.
  static ProjectEntity toEntity(ProjectModel model) {
    return ProjectEntity(
      id: model.id,
      contourId: model.contourId,
      userId: model.userId,
      data: model.data,
      lastOpened: model.lastOpened,
      createdAt: model.createdAt,
    );
  }

  /// Converts an entity to a model.
  static ProjectModel toModel(ProjectEntity entity) {
    return ProjectModel(
      id: entity.id,
      contourId: entity.contourId,
      userId: entity.userId,
      data: entity.data,
      lastOpened: entity.lastOpened,
      createdAt: entity.createdAt,
    );
  }
}
