import 'package:equatable/equatable.dart';

/// Domain entity representing a started (work in progress) project.
class WorkInProgressEntity extends Equatable {
  /// Identifier of the contour the project is based on.
  final String contourId;

  /// Path or URL to the project thumbnail, if any.
  final String? thumbnailPath;

  /// Timestamp of the last change to the project.
  final DateTime lastOpened;

  /// Creates a [WorkInProgressEntity].
  const WorkInProgressEntity({
    required this.contourId,
    required this.thumbnailPath,
    required this.lastOpened,
  });

  @override
  List<Object?> get props => <Object?>[contourId, thumbnailPath, lastOpened];
}
