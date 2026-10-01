import '../../../domain.dart';

/// Saves a project to local storage and triggers cloud sync.
class SaveProjectUseCase implements FutureUseCase<ProjectEntity, void> {
  /// Underlying canvas repository.
  final CanvasRepository repository;

  /// Creates a use case with the given [repository].
  const SaveProjectUseCase({required this.repository});

  @override
  Future<void> execute([ProjectEntity? params]) {
    if (params == null) {
      throw ArgumentError('project must not be null');
    }
    return repository.saveProject(params);
  }
}
