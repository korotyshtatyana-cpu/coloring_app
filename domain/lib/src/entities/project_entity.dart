import 'package:equatable/equatable.dart';

/// Domain entity representing a user's coloring project.
class ProjectEntity extends Equatable {
  /// Unique project identifier.
  final String id;

  /// Identifier of the associated contour.
  final String contourId;

  /// Identifier of the project owner.
  final String userId;

  /// Serialized project data (strokes, settings).
  final Map<String, dynamic> data;

  /// Last time the project was opened.
  final DateTime lastOpened;

  /// Project creation time.
  final DateTime createdAt;

  /// Creates a [ProjectEntity].
  const ProjectEntity({
    required this.id,
    required this.contourId,
    required this.userId,
    required this.data,
    required this.lastOpened,
    required this.createdAt,
  });

  @override
  List<Object?> get props =>
      <Object?>[id, contourId, userId, data, lastOpened, createdAt];
}
