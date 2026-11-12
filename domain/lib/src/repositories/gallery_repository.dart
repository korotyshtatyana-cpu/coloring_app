import '../entities/contour_access_type.dart';
import '../entities/contour_category.dart';
import '../entities/contour_entity.dart';
import '../entities/work_in_progress_entity.dart';

/// Repository for gallery and contour operations.
abstract class GalleryRepository {
  /// Fetches a paginated list of contours.
  ///
  /// [accessType] limits the result to contours with that monetization type.
  /// [createdAfter] limits the result to contours created at or after that
  /// moment; the remote implementation applies it in the query and returns
  /// the result newest first.
  Future<List<ContourEntity>> getContours({
    required int limit,
    required int offset,
    ContourCategory? category,
    ContourAccessType? accessType,
    DateTime? createdAfter,
  });

  /// Fetches a paginated list of contours by their identifiers.
  Future<List<ContourEntity>> getContoursByIds({
    required List<String> ids,
    required int limit,
    required int offset,
    ContourCategory? category,
  });

  /// Toggles the favorite status of a contour for the current user.
  Future<void> toggleFavorite(String contourId);

  /// Returns favorite contour identifiers for the current user.
  Future<List<String>> getFavoriteIds();

  /// Returns started (work in progress) projects ordered by the date of
  /// the last change, most recent first.
  Future<List<WorkInProgressEntity>> getWorkInProgress();

  /// Loads a single cached contour by its identifier.
  Future<ContourEntity?> getContourById(String id);

  /// Returns the unique categories that have at least one contour.
  ///
  /// Categories are flattened across all contours, so a contour with several
  /// categories contributes each of them.
  Future<List<ContourCategory>> getUsedCategories();
}
