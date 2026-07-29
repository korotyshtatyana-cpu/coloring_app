import '../../../domain.dart';
import '../use_case.dart';

/// Parameters for [GetContoursByIdsUseCase].
class GetContoursByIdsParams {
  /// Contour identifiers to fetch.
  final List<String> ids;

  /// Maximum number of items to return.
  final int limit;

  /// Offset for pagination.
  final int offset;

  /// Optional category filter.
  final ContourCategory? category;

  /// Creates parameters for fetching contours by identifiers.
  const GetContoursByIdsParams({
    required this.ids,
    required this.limit,
    required this.offset,
    this.category,
  });
}

/// Fetches a paginated list of contours by their identifiers.
class GetContoursByIdsUseCase
    implements FutureUseCase<GetContoursByIdsParams, List<ContourEntity>> {
  final GalleryRepository _repository;

  /// Creates a use case with the given [repository].
  const GetContoursByIdsUseCase({required GalleryRepository repository})
      : _repository = repository;

  @override
  Future<List<ContourEntity>> execute([GetContoursByIdsParams? params]) {
    final GetContoursByIdsParams p = params ??
        const GetContoursByIdsParams(
          ids: <String>[],
          limit: 20,
          offset: 0,
        );

    return _repository.getContoursByIds(
      ids: p.ids,
      limit: p.limit,
      offset: p.offset,
      category: p.category == ContourCategory.all ? null : p.category,
    );
  }
}
