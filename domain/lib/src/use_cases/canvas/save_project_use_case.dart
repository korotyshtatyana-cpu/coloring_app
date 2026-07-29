import '../../../domain.dart';
import '../use_case.dart';

/// Saves a project to local storage and triggers cloud sync.
class SaveProjectUseCase implements FutureUseCase<ProjectEntity, void> {
  final CanvasRepository _repository;

  /// Creates a use case with the given [repository].
  const SaveProjectUseCase({required CanvasRepository repository})
      : _repository = repository;

  @override
  Future<void> execute([ProjectEntity? params]) {
    if (params == null) {
      throw ArgumentError('project must not be null');
    }
    return _repository.saveProject(params);
  }
}
