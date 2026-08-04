import '../../../domain.dart';
import '../use_case.dart';

/// Returns identifiers of contours marked as favorite by the current user.
class GetFavoriteIdsUseCase implements FutureUseCase<NoParams, List<String>> {
  final GalleryRepository _repository;

  /// Creates a use case with the given [_repository].
  const GetFavoriteIdsUseCase({required this._repository});

  @override
  Future<List<String>> execute([NoParams? params]) {
    return _repository.getFavoriteIds();
  }
}
