import '../../../domain.dart';
import '../use_case.dart';

/// Returns identifiers of contours with started projects mapped to the
/// project's thumbnail path, if any.
class GetWorkInProgressUseCase
    implements FutureUseCase<NoParams, Map<String, String?>> {
  final GalleryRepository _repository;

  /// Creates a use case with the given [_repository].
  const GetWorkInProgressUseCase({required this._repository});

  @override
  Future<Map<String, String?>> execute([NoParams? params]) {
    return _repository.getWorkInProgressThumbnails();
  }
}
