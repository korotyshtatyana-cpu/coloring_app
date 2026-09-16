import 'package:drift/drift.dart';
import 'package:core/core.dart';
import 'package:domain/domain.dart';

import '../../data.dart';

/// Local provider for canvas projects and strokes using Drift.
class CanvasLocalProvider {
  final AppDatabase _database;

  /// Creates a provider with the given [_database].
  CanvasLocalProvider({required this._database});

  /// Saves the project and its strokes locally.
  Future<void> saveProject(
      ProjectModel project, List<StrokeEntity> strokes) async {
    await _database.into(_database.projects).insertOnConflictUpdate(
          _toProjectCompanion(project),
        );

    await (_database.delete(_database.strokes)
          ..where(($StrokesTable row) => row.projectId.equals(project.id)))
        .go();

    for (final StrokeEntity stroke in strokes) {
      final StrokeModel model = StrokeMapper.toModel(stroke, project.id);
      await _database.into(_database.strokes).insertOnConflictUpdate(
            _toStrokeCompanion(model),
          );
    }
  }

  /// Loads a project for the given contour.
  Future<ProjectModel?> loadProject(String contourId) async {
    final Project? row = await (_database.select(_database.projects)
          ..where(($ProjectsTable row) => row.contourId.equals(contourId)))
        .getSingleOrNull();

    return row == null ? null : _projectFromCompanion(row);
  }

  /// Loads strokes for the given project.
  Future<List<StrokeEntity>> loadStrokes(String projectId) async {
    final List<Stroke> rows = await (_database.select(_database.strokes)
          ..where(($StrokesTable row) => row.projectId.equals(projectId)))
        .get();

    return rows
        .map((Stroke row) => StrokeMapper.toEntity(_strokeFromCompanion(row)))
        .toList();
  }

  /// Loads available tools from the database.
  Future<List<ToolEntity>> getAvailableTools() async {
    final List<Brushe> rows = await _database.select(_database.brushes).get();
    
    // Seed database if empty
    if (rows.isEmpty) {
      await _seedBrushes();
      return getAvailableTools();
    }

    return rows.map((row) => ToolEntity(
      id: row.id,
      nameKey: row.nameKey,
      previewPath: row.previewPath,
      isPressureSensitive: row.isPressureSensitive,
    )).toList();
  }

  Future<void> _seedBrushes() async {
    final seeds = [
      BrushesCompanion.insert(
        id: 'round_basic',
        nameKey: LocaleKeys.brush_round_basic,
        previewPath: '',
        isPressureSensitive: false,
      ),
      BrushesCompanion.insert(
        id: 'fine_liner',
        nameKey: LocaleKeys.brush_fine_liner,
        previewPath: '',
        isPressureSensitive: true,
      ),
    ];

    for (final companion in seeds) {
      await _database.into(_database.brushes).insert(companion);
    }
  }

  /// Deletes all strokes for the given project.
  Future<void> clearStrokes(String projectId) async {
    await (_database.delete(_database.strokes)
          ..where(($StrokesTable row) => row.projectId.equals(projectId)))
        .go();
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
