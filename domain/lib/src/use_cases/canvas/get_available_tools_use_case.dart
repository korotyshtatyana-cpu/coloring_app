import '../../../domain.dart';
import '../use_case.dart';

/// Retrieves the list of all available drawing tools (brushes and erasers).
class GetAvailableToolsUseCase implements FutureUseCase<NoParams, List<ToolEntity>> {
  final CanvasRepository _repository;

  /// Creates a use case with the given [_repository].
  const GetAvailableToolsUseCase({required this._repository});

  @override
  Future<List<ToolEntity>> execute([NoParams? params]) {
    return _repository.getAvailableTools();
  }
}
