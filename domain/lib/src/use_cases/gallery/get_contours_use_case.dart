import '../../../domain.dart';

/// Parameters for [GetContoursUseCase].
class GetContoursParams {
  /// Maximum number of items to return.
  final int limit;

  /// Offset for pagination.
  final int offset;

  /// Optional category filter.
  final ContourCategory? category;

  /// Optional access type filter, for example [ContourAccessType.free].
  final ContourAccessType? accessType;

  /// Whether to return only contours created within the "new" period.
  ///
  /// When `true`, [GetContoursUseCase] converts it into a `created_at` filter
  /// and the repository performs a separate filtered query instead of
  /// filtering an already loaded list on the client.
  final bool onlyNew;

  /// Creates parameters for fetching contours.
  const GetContoursParams({
    required this.limit,
    required this.offset,
    this.category,
    this.accessType,
    this.onlyNew = false,
  });
}

/// Fetches a paginated list of contours.
class GetContoursUseCase
    implements FutureUseCase<GetContoursParams, List<ContourEntity>> {
  /// Window during which a contour is considered new.
  static const Duration newContoursPeriod = Duration(days: 30);

  final GalleryRepository _repository;

  /// Creates a use case with the given [_repository].
  const GetContoursUseCase({required this._repository});

  @override
  Future<List<ContourEntity>> execute([GetContoursParams? params]) {
    final GetContoursParams p =
        params ?? const GetContoursParams(limit: 20, offset: 0);

    return _repository.getContours(
      limit: p.limit,
      offset: p.offset,
      category: p.category == ContourCategory.all ? null : p.category,
      accessType: p.accessType,
      createdAfter: p.onlyNew
          ? DateTime.now().toUtc().subtract(newContoursPeriod)
          : null,
    );
  }
}
