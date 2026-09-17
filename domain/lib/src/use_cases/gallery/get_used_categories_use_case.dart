import '../../../domain.dart';
import '../use_case.dart';

/// Fetches the list of categories that have at least one contour.
class GetUsedCategoriesUseCase implements FutureUseCase<void, List<ContourCategory>> {
  final GalleryRepository _repository;

  /// Creates a use case with the given [_repository].
  const GetUsedCategoriesUseCase({required this._repository});

  @override
  Future<List<ContourCategory>> execute([void params]) {
    return _repository.getUsedCategories();
  }
}
