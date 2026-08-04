import 'package:domain/domain.dart';
import '../models/contour_model.dart';
import '../providers/gallery_local_provider.dart';
import '../providers/gallery_remote_provider.dart';
import '../mappers/contour_mapper.dart';

/// Implementation of [GalleryRepository] combining remote and local providers.
class GalleryRepositoryImpl implements GalleryRepository {
  final GalleryRemoteProvider _remoteProvider;
  final GalleryLocalProvider _localProvider;

  /// Creates a repository with the given providers.
  GalleryRepositoryImpl({
    required this._remoteProvider,
    required this._localProvider,
  });

  @override
  Future<List<ContourEntity>> getContours({
    required int limit,
    required int offset,
    ContourCategory? category,
  }) async {
    try {
      final contours = await _remoteProvider.getContours(
        limit: limit,
        offset: offset,
        category: category,
      );
      await _localProvider.cacheContours(contours);
      return contours.map(ContourMapper.toEntity).toList();
    } catch (_) {
      final cached = await _localProvider.getCachedContours();
      final filtered = cached
          .where(
            (ContourModel contour) =>
                category == null || contour.category == category,
          )
          .toList();
      return _paginate(filtered, offset: offset, limit: limit)
          .map(ContourMapper.toEntity)
          .toList();
    }
  }

  @override
  Future<List<ContourEntity>> getContoursByIds({
    required List<String> ids,
    required int limit,
    required int offset,
    ContourCategory? category,
  }) async {
    if (ids.isEmpty) {
      return <ContourEntity>[];
    }

    try {
      final contours = await _remoteProvider.getContoursByIds(
        ids: ids,
        limit: limit,
        offset: offset,
        category: category,
      );
      await _localProvider.cacheContours(contours);
      return contours.map(ContourMapper.toEntity).toList();
    } catch (_) {
      final cached = await _localProvider.getCachedContours();
      final filtered = cached
          .where((ContourModel contour) => ids.contains(contour.id))
          .where(
            (ContourModel contour) =>
                category == null || contour.category == category,
          )
          .toList();
      return _paginate(filtered, offset: offset, limit: limit)
          .map(ContourMapper.toEntity)
          .toList();
    }
  }

  List<ContourEntity> _filterByCategoryAndPaginate(
    List<ContourModel> contours, {
    required ContourCategory category,
    required int offset,
    required int limit,
  }) {
    final filtered = contours
        .where((ContourModel contour) => contour.category == category)
        .toList();
    return _paginate(filtered, offset: offset, limit: limit)
        .map(ContourMapper.toEntity)
        .toList();
  }

  List<ContourModel> _paginate(
    List<ContourModel> contours, {
    required int offset,
    required int limit,
  }) {
    final end = (offset + limit).clamp(0, contours.length);
    if (offset >= contours.length) {
      return <ContourModel>[];
    }
    return contours.sublist(offset, end);
  }

  @override
  Future<void> toggleFavorite(String contourId) {
    return _remoteProvider.toggleFavorite(contourId);
  }

  @override
  Future<List<String>> getFavoriteIds() {
    return _remoteProvider.getFavoriteIds();
  }

  @override
  Future<List<String>> getWorkInProgress() {
    return _localProvider.getWorkInProgressIds();
  }

  @override
  Future<ContourEntity?> getContourById(String id) async {
    final cached = await _localProvider.getContourById(id);
    if (cached != null) {
      return ContourMapper.toEntity(cached);
    }
    return null;
  }
}
