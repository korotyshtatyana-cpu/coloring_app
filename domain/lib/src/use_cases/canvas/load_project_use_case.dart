import '../../../domain.dart';
import '../use_case.dart';

/// Loads a project for the given contour identifier.
class LoadProjectUseCase implements FutureUseCase<String, ProjectEntity?> {
  final CanvasRepository _repository;

  /// Creates a use case with the given [_repository].
  const LoadProjectUseCase({required this._repository});

  @override
  Future<ProjectEntity?> execute([String? params]) {
    if (params == null) {
      throw ArgumentError('contourId must not be null');
    }
    return _repository.loadProject(params);
  }
}
