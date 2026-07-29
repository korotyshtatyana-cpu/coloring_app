import 'package:drift/drift.dart';

import '../../data.dart';

/// Local provider that caches contour data using Drift.
class GalleryLocalProvider {
  final AppDatabase _database;

  /// Creates a provider with the given [database].
  GalleryLocalProvider({required AppDatabase database}) : _database = database;

  /// Caches a list of contours, replacing existing rows.
  Future<void> cacheContours(List<ContourModel> contours) async {
    await _database.batch((Batch batch) {
      batch.insertAllOnConflictUpdate(
        _database.contours,
        contours.map((ContourModel contour) => _toCompanion(contour)),
      );
    });
  }

  /// Loads a single cached contour by its identifier.
  Future<ContourModel?> getContourById(String id) async {
    final Contour? row = await (_database.select(_database.contours)
          ..where(($ContoursTable row) => row.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  /// Loads cached contours from the local database.
  Future<List<ContourModel>> getCachedContours() async {
    final List<Contour> rows = await _database.select(_database.contours).get();
    return rows.map((Contour row) => _fromRow(row)).toList();
  }

  /// Returns contour identifiers that have a started local project.
  Future<List<String>> getWorkInProgressIds() async {
    final List<Project> rows = await _database.select(_database.projects).get();
    return rows.map((Project row) => row.contourId).toSet().toList();
  }

  ContoursCompanion _toCompanion(ContourModel contour) {
    return ContoursCompanion.insert(
      id: contour.id,
      title: contour.title,
      category: contour.category,
      svgData: contour.svgData,
      previewUrl: contour.previewUrl,
      createdAt: contour.createdAt ?? DateTime.now(),
    );
  }

  ContourModel _fromRow(Contour row) {
    return ContourModel(
      id: row.id,
      title: row.title,
      category: row.category,
      svgData: row.svgData,
      previewUrl: row.previewUrl,
      createdAt: row.createdAt,
    );
  }
}
