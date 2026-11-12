import '../../../domain.dart';

/// Fetches the unique categories used by at least one contour.
///
/// A contour can belong to several categories, so the repository flattens the
/// `categories` lists (with a fallback to the legacy `category` column) and
/// removes duplicates before returning them.
class GetUsedCategoriesUseCase
    implements FutureUseCase<void, List<ContourCategory>> {
  final GalleryRepository _repository;

  /// Creates a use case with the given [_repository].
  const GetUsedCategoriesUseCase({required this._repository});

  @override
  Future<List<ContourCategory>> execute([void params]) {
    return _repository.getUsedCategories();
  }
}
