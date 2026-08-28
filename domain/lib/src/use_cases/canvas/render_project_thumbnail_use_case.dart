import '../../../domain.dart';
import '../use_case.dart';

/// Renders a project thumbnail image and returns its file path.
class RenderProjectThumbnailUseCase
    implements FutureUseCase<ExportImageParams, String?> {
  final CanvasRepository _repository;

  /// Creates a use case with the given [_repository].
  const RenderProjectThumbnailUseCase({required this._repository});

  @override
  Future<String?> execute([ExportImageParams? params]) {
    if (params == null) {
      throw ArgumentError('ExportImageParams must not be null');
    }
    return _repository.renderProjectThumbnail(params);
  }
}
