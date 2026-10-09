import 'package:domain/domain.dart';
import 'package:drift/drift.dart';

import '../../data.dart';

/// Local provider that caches contour data using Drift.
class GalleryLocalProvider {
  final AppDatabase _database;

  /// Creates a provider with the given [_database].
  GalleryLocalProvider({required this._database});

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
    final Contour? row = await (_database.select(
      _database.contours,
    )..where(($ContoursTable row) => row.id.equals(id))).getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  /// Loads cached contours from the local database.
  Future<List<ContourModel>> getCachedContours() async {
    final List<Contour> rows = await _database.select(_database.contours).get();
    return rows.map((Contour row) => _fromRow(row)).toList();
  }

  /// Returns started (work in progress) projects ordered by the date of
  /// the last change, most recent first. Only projects with at least one stroke
  /// are included.
  Future<List<WorkInProgressEntity>> getWorkInProgress() async {
    final List<Project> rows =
        await (_database.select(_database.projects)
              ..orderBy(<OrderingTerm Function($ProjectsTable)>[
                ($ProjectsTable row) => OrderingTerm.desc(row.lastOpened),
              ]))
            .get();

    final List<WorkInProgressEntity> result = <WorkInProgressEntity>[];
    for (final Project row in rows) {
      final List<Stroke> strokes = await (_database.select(
        _database.strokes,
      )..where(($StrokesTable s) => s.projectId.equals(row.id))).get();

      if (strokes.isNotEmpty) {
        result.add(
          WorkInProgressEntity(
            contourId: row.contourId,
            thumbnailPath: row.data['thumbnailPath'] as String?,
            lastOpened: row.lastOpened,
          ),
        );
      }
    }
    return result;
  }

  ContoursCompanion _toCompanion(ContourModel contour) {
    return ContoursCompanion.insert(
      id: contour.id,
      title: contour.title,
      category: contour.category.name,
      svgUrl: contour.svgUrl,
      previewUrl: contour.previewUrl,
      createdAt: contour.createdAt ?? DateTime.now(),
      accessType: Value(contour.accessType),
      price: Value(contour.price),
      productId: Value(contour.productId),
    );
  }

  ContourModel _fromRow(Contour row) {
    return ContourModel(
      id: row.id,
      title: row.title,
      category: ContourCategory.values.byName(row.category),
      svgUrl: row.svgUrl,
      previewUrl: row.previewUrl,
      createdAt: row.createdAt,
      accessType: row.accessType,
      price: row.price,
      productId: row.productId,
    );
  }
}
