import '../../../domain.dart';
import '../use_case.dart';

/// Returns identifiers of contours with started projects.
class GetWorkInProgressUseCase
    implements FutureUseCase<NoParams, List<String>> {
  final GalleryRepository _repository;

  /// Creates a use case with the given [repository].
  const GetWorkInProgressUseCase({required GalleryRepository repository})
      : _repository = repository;

  @override
  Future<List<String>> execute([NoParams? params]) {
    return _repository.getWorkInProgress();
  }
}
