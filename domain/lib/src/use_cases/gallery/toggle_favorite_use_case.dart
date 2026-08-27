import '../../../domain.dart';
import '../use_case.dart';

/// Toggles favorite status of a contour for the current user.
class ToggleFavoriteUseCase implements FutureUseCase<String, void> {
  final GalleryRepository _repository;

  /// Creates a use case with the given [_repository].
  const ToggleFavoriteUseCase({required this._repository});

  @override
  Future<void> execute([String? params]) {
    if (params == null) {
      throw ArgumentError('contourId must not be null');
    }
    return _repository.toggleFavorite(params);
  }
}
