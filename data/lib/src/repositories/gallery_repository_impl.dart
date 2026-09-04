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
  Future<Map<String, String?>> getWorkInProgressThumbnails() async {
    final Map<String, String?> local =
        await _localProvider.getWorkInProgressThumbnails();

    try {
      final Map<String, String?> remote =
          await _remoteProvider.getWorkInProgressThumbnails();

      // Local entries always count (they exist on this device). A local
      // HTTP thumbnail wins over the remote one because it is the freshest.
      // A local device-file thumbnail only fills the gap when there is no
      // remote URL: the file may be older than the remote version (it is
      // kept only when the upload failed), while remote URLs are
      // cache-busted on every save.
      final Map<String, String?> merged = Map<String, String?>.of(remote);
      local.forEach((String contourId, String? thumbnail) {
        final bool hasRemote = merged[contourId] != null;
        final bool localIsRemoteUrl =
            thumbnail != null && thumbnail.startsWith('http');
        if (localIsRemoteUrl || !hasRemote) {
          merged[contourId] = thumbnail;
        }
      });
      return merged;
    } catch (_) {
      // Offline or unauthenticated: fall back to local data only.
      return local;
    }
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
