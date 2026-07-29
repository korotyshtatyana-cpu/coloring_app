import '../entities/contour_category.dart';
import '../entities/contour_entity.dart';

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

  /// Returns contour identifiers with started projects.
  Future<List<String>> getWorkInProgress();

  /// Loads a single cached contour by its identifier.
  Future<ContourEntity?> getContourById(String id);
}
