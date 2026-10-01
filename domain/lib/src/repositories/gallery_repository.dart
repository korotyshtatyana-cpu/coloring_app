import '../entities/contour_category.dart';
import '../entities/contour_entity.dart';
import '../entities/work_in_progress_entity.dart';

/// Repository for gallery and contour operations.
abstract class GalleryRepository {
  /// Fetches a paginated list of contours.
  Future<List<ContourEntity>> getContours({
    required int limit,
    required int offset,
    ContourCategory? category,
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

  /// Returns the list of categories that have at least one contour.
  Future<List<ContourCategory>> getUsedCategories();
}
