import '../../../domain.dart';
import '../use_case.dart';

/// Exports a project as an image and returns the file path.
class ExportImageUseCase implements FutureUseCase<ExportImageParams, String?> {
  final CanvasRepository _repository;

  /// Creates a use case with the given [_repository].
  const ExportImageUseCase({required this._repository});

  @override
  Future<String?> execute([ExportImageParams? params]) {
    if (params == null) {
      throw ArgumentError('ExportImageParams must not be null');
    }
    return _repository.exportImage(params);
  }
}
