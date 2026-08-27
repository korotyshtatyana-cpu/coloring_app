import '../../../domain.dart';
import '../use_case.dart';

/// Parameters for [AddStrokeUseCase].
class AddStrokeParams {
  /// Target project identifier.
  final String projectId;

  /// Stroke to add.
  final StrokeEntity stroke;

  /// Creates parameters for adding a stroke.
  const AddStrokeParams({
    required this.projectId,
    required this.stroke,
  });
}

/// Adds a stroke to a project.
class AddStrokeUseCase implements FutureUseCase<AddStrokeParams, void> {
  final CanvasRepository _repository;

  /// Creates a use case with the given [_repository].
  const AddStrokeUseCase({required this._repository});

  @override
  Future<void> execute([AddStrokeParams? params]) {
    if (params == null) {
      throw ArgumentError('AddStrokeParams must not be null');
    }
    return _repository.addStroke(params.projectId, params.stroke);
  }
}
