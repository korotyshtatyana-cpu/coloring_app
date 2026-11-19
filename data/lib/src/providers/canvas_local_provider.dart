import 'dart:io';

import 'package:drift/drift.dart';
import 'package:core/core.dart';
import 'package:domain/domain.dart';
import 'package:path_provider/path_provider.dart';

import '../../data.dart';

/// Local provider for canvas projects and strokes using Drift.
class CanvasLocalProvider {
  final AppDatabase _database;

  /// Creates a provider with the given [_database].
  CanvasLocalProvider({required this._database});

  /// Saves the project and its strokes locally.
  Future<void> saveProject(ProjectModel project, List<StrokeEntity> strokes) async {
    await _database.transaction(() async {
      await _database.into(_database.projects).insertOnConflictUpdate(_toProjectCompanion(project));

      await (_database.delete(
        _database.strokes,
      )..where(($StrokesTable row) => row.projectId.equals(project.id))).go();

      // One batch insert instead of an awaited statement per stroke: a full
      // rewrite of many strokes took seconds; with batching it is a single
      // round trip.
      await _database.batch((Batch batch) {
        for (final StrokeEntity stroke in strokes) {
          final StrokeModel model = StrokeMapper.toModel(stroke, project.id);
          batch.insert(
            _database.strokes,
            _toStrokeCompanion(model),
            mode: InsertMode.insertOrReplace,
          );
        }
      });
    });
  }

  /// Appends a single finished stroke to an already-persisted project.
  /// O(1) per stroke: older strokes are already stored ("baked"), they are
  /// never rewritten unless the project as a whole is re-saved.
  Future<void> appendStroke(String projectId, StrokeEntity stroke) async {
    final StrokeModel model = StrokeMapper.toModel(stroke, projectId);
    await _database.into(_database.strokes).insertOnConflictUpdate(_toStrokeCompanion(model));
  }

  /// Loads a project for the given contour.
  Future<ProjectModel?> loadProject(String contourId) async {
    final Project? row = await (_database.select(
      _database.projects,
    )..where(($ProjectsTable row) => row.contourId.equals(contourId))).getSingleOrNull();

    return row == null ? null : _projectFromCompanion(row);
  }

  /// Loads strokes for the given project.
  Future<List<StrokeEntity>> loadStrokes(String projectId) async {
    final List<Stroke> rows = await (_database.select(
      _database.strokes,
    )..where(($StrokesTable row) => row.projectId.equals(projectId))).get();

    return rows.map((Stroke row) => StrokeMapper.toEntity(_strokeFromCompanion(row))).toList();
  }

  /// Loads available tools from the database.
  ///
  /// Built-in tools are inserted when missing, so an existing install that was
  /// seeded before a tool was added still receives it without wiping the
  /// brushes table. Rows synced from Supabase keep their name and preview.
  Future<List<ToolEntity>> getAvailableTools() async {
    await _seedDefaultBrushes();
    final List<Brushe> rows = await _database.select(_database.brushes).get();

    return rows
        .map(
          (row) => ToolMapper.fromFields(
            id: row.id,
            nameKey: row.nameKey,
            previewPath: row.previewPath,
            isPressureSensitive: row.isPressureSensitive,
          ),
        )
        .toList();
  }

  /// Inserts the built-in tool catalog without overwriting synced rows.
  Future<void> _seedDefaultBrushes() async {
    await _database.batch((Batch batch) {
      for (final ToolEntity tool in _defaultTools) {
        batch.insert(
          _database.brushes,
          BrushesCompanion.insert(
            id: tool.id,
            nameKey: tool.nameKey,
            previewPath: tool.previewPath,
            isPressureSensitive: tool.isPressureSensitive,
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }

  /// Inserts or updates tool rows fetched from Supabase.
  Future<void> upsertTools(List<ToolEntity> tools) async {
    if (tools.isEmpty) {
      return;
    }

    await _database.batch((Batch batch) {
      for (final ToolEntity tool in tools) {
        batch.insert(
          _database.brushes,
          BrushesCompanion.insert(
            id: tool.id,
            nameKey: tool.nameKey,
            previewPath: tool.previewPath,
            isPressureSensitive: tool.isPressureSensitive,
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  static const List<ToolEntity> _defaultTools = <ToolEntity>[
    ToolEntity(
      id: 'round_basic',
      nameKey: LocaleKeys.brush_round_basic,
      previewPath: '',
      isPressureSensitive: false,
      brushType: BrushType.circle,
    ),
    ToolEntity(
      id: 'fine_liner',
      nameKey: LocaleKeys.brush_fine_liner,
      previewPath: '',
      isPressureSensitive: true,
      brushType: BrushType.circle,
    ),
    ToolEntity(
      id: 'soft_round_basic',
      nameKey: LocaleKeys.brush_soft_round_basic,
      previewPath: '',
      isPressureSensitive: false,
      brushType: BrushType.softRoundBasic,
    ),
    ToolEntity(
      id: 'soft_liner',
      nameKey: LocaleKeys.brush_soft_liner,
      previewPath: '',
      isPressureSensitive: true,
      brushType: BrushType.softLiner,
    ),
  ];

  /// Deletes all strokes for the given project.
  Future<void> clearStrokes(String projectId) async {
    await (_database.delete(
      _database.strokes,
    )..where(($StrokesTable row) => row.projectId.equals(projectId))).go();
  }

  /// Deletes a project and its strokes/thumbnails by contour ID.
  Future<void> deleteProject(String contourId) async {
    final ProjectModel? project = await loadProject(contourId);
    if (project != null) {
      await _database.transaction(() async {
        await (_database.delete(
          _database.strokes,
        )..where(($StrokesTable row) => row.projectId.equals(project.id))).go();
        await (_database.delete(
          _database.projects,
        )..where(($ProjectsTable row) => row.id.equals(project.id))).go();
      });
      await _deleteThumbnailFor(contourId);
    }
  }

  Future<void> _deleteThumbnailFor(String contourId) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final File file = File('${directory.path}/thumbnails/$contourId.png');
    if (file.existsSync()) {
      await file.delete();
    }
  }

  /// Deletes all locally stored user data: projects, their strokes and
  /// rendered thumbnails.
  Future<void> clearUserData() async {
    await _database.transaction(() async {
      await _database.delete(_database.strokes).go();
      await _database.delete(_database.projects).go();
    });
    await _deleteThumbnails();
  }

  Future<void> _deleteThumbnails() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final Directory thumbnailsDir = Directory('${directory.path}/thumbnails');
    if (thumbnailsDir.existsSync()) {
      await thumbnailsDir.delete(recursive: true);
    }
  }

  ProjectsCompanion _toProjectCompanion(ProjectModel project) {
    return ProjectsCompanion.insert(
      id: project.id,
      contourId: project.contourId,
      userId: project.userId,
      data: project.data,
      lastOpened: project.lastOpened,
      createdAt: project.createdAt,
    );
  }

  ProjectModel _projectFromCompanion(Project row) {
    return ProjectModel(
      id: row.id,
      contourId: row.contourId,
      userId: row.userId,
      data: row.data,
      lastOpened: row.lastOpened,
      createdAt: row.createdAt,
    );
  }

  StrokesCompanion _toStrokeCompanion(StrokeModel model) {
    return StrokesCompanion.insert(
      id: model.id,
      projectId: model.projectId,
      points: model.points,
      color: model.color,
      size: model.size,
      opacity: model.opacity,
      brushType: model.brushType.name,
      brushId: Value(model.brushId),
      isPressureSensitive: Value(model.isPressureSensitive),
    );
  }

  StrokeModel _strokeFromCompanion(Stroke row) {
    return StrokeModel(
      id: row.id,
      projectId: row.projectId,
      points: row.points,
      color: row.color,
      size: row.size,
      opacity: row.opacity,
      brushType: BrushType.values.byName(row.brushType),
      brushId: row.brushId,
      isPressureSensitive: row.isPressureSensitive,
    );
  }
}
