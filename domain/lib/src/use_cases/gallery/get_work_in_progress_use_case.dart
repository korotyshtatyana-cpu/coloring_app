import '../../../domain.dart';
import '../use_case.dart';

/// Returns started (work in progress) projects ordered by the date of
/// the last change, most recent first.
class GetWorkInProgressUseCase
    implements FutureUseCase<NoParams, List<WorkInProgressEntity>> {
  final GalleryRepository _repository;

  /// Creates a use case with the given [_repository].
  const GetWorkInProgressUseCase({required this._repository});

  @override
  Future<List<WorkInProgressEntity>> execute([NoParams? params]) {
    return _repository.getWorkInProgress();
  }
}
