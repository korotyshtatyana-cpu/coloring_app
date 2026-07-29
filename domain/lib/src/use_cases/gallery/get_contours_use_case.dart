import '../../../domain.dart';
import '../use_case.dart';

/// Parameters for [GetContoursUseCase].
class GetContoursParams {
  /// Maximum number of items to return.
  final int limit;

  /// Offset for pagination.
  final int offset;

  /// Optional category filter.
  final String? category;

  /// Creates parameters for fetching contours.
  const GetContoursParams({
    required this.limit,
    required this.offset,
    this.category,
  });
}

/// Fetches a paginated list of contours.
class GetContoursUseCase
    implements FutureUseCase<GetContoursParams, List<ContourEntity>> {
  final GalleryRepository _repository;

  /// Creates a use case with the given [repository].
  const GetContoursUseCase({required GalleryRepository repository})
      : _repository = repository;

  @override
  Future<List<ContourEntity>> execute([GetContoursParams? params]) {
    final GetContoursParams p = params ??
        const GetContoursParams(
          limit: 20,
          offset: 0,
        );

    return _repository.getContours(
      limit: p.limit,
      offset: p.offset,
      category: p.category,
    );
  }
}
