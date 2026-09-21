import 'package:flutter/foundation.dart';
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
        category: category,
      );
      await _localProvider.cacheContours(contours);
      return _paginate(
        _sortByIds(contours, ids),
        offset: offset,
        limit: limit,
      ).map(ContourMapper.toEntity).toList();
    } catch (_) {
      final cached = await _localProvider.getCachedContours();
      final filtered = cached
          .where((ContourModel contour) => ids.contains(contour.id))
          .where(
            (ContourModel contour) =>
                category == null || contour.category == category,
          )
          .toList();
      return _paginate(
        _sortByIds(filtered, ids),
        offset: offset,
        limit: limit,
      ).map(ContourMapper.toEntity).toList();
    }
  }

  /// Orders [contours] to match the order of [ids].
  List<ContourModel> _sortByIds(List<ContourModel> contours, List<String> ids) {
    final Map<String, int> indexById = <String, int>{
      for (int i = 0; i < ids.length; i++) ids[i]: i,
    };
    contours.sort(
      (ContourModel a, ContourModel b) => (indexById[a.id] ?? ids.length)
          .compareTo(indexById[b.id] ?? ids.length),
    );
    return contours;
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
  Future<List<String>> getFavoriteIds() async {
    try {
      return await _remoteProvider.getFavoriteIds();
    } catch (e) {
      debugPrint('Failed to fetch favorite IDs: $e');
      return <String>[];
    }
  }

  @override
  Future<List<WorkInProgressEntity>> getWorkInProgress() async {
    final List<WorkInProgressEntity> local =
        await _localProvider.getWorkInProgress();

    try {
      final List<WorkInProgressEntity> remote =
          await _remoteProvider.getWorkInProgress();

      // Local entries always count (they exist on this device). A local
      // HTTP thumbnail wins over the remote one because it is the freshest.
      // A local device-file thumbnail only fills the gap when there is no
      // remote URL: the file may be older than the remote version (it is
      // kept only when the upload failed), while remote URLs are
      // cache-busted on every save.
      final Map<String, WorkInProgressEntity> merged =
          <String, WorkInProgressEntity>{
        for (final WorkInProgressEntity entry in remote) entry.contourId: entry,
      };
      for (final WorkInProgressEntity entry in local) {
        final WorkInProgressEntity? remoteEntry = merged[entry.contourId];
        final String? remoteThumbnail = remoteEntry?.thumbnailPath;
        final bool localIsRemoteUrl =
            entry.thumbnailPath != null && entry.thumbnailPath!.startsWith('http');

        final String? thumbnail =
            (localIsRemoteUrl || remoteThumbnail == null)
                ? entry.thumbnailPath
                : remoteThumbnail;
        final DateTime lastOpened =
            remoteEntry != null && remoteEntry.lastOpened.isAfter(entry.lastOpened)
                ? remoteEntry.lastOpened
                : entry.lastOpened;

        merged[entry.contourId] = WorkInProgressEntity(
          contourId: entry.contourId,
          thumbnailPath: thumbnail,
          lastOpened: lastOpened,
        );
      }

      return merged.values.toList()
        ..sort(
          (WorkInProgressEntity a, WorkInProgressEntity b) =>
              b.lastOpened.compareTo(a.lastOpened),
        );
    } catch (_) {
      // Offline or unauthenticated: fall back to local data only (already
      // ordered by the provider).
      return local;
    }
  }

  @override
  Future<ContourEntity?> getContourById(String id) async {
    try {
      final cached = await _localProvider.getContourById(id);
      if (cached != null) {
        return ContourMapper.toEntity(cached);
      }
    } catch (e) {
      debugPrint('Error getting contour by ID: $e');
    }
    return null;
  }

  @override
  Future<List<ContourCategory>> getUsedCategories() async {
    try {
      return await _remoteProvider.getUsedCategories();
    } catch (_) {
      final cached = await _localProvider.getCachedContours();
      return cached.map((ContourModel contour) => contour.category).toSet().toList();
    }
  }
}
