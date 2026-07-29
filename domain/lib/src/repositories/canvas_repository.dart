import '../entities/project_entity.dart';
import '../entities/stroke_entity.dart';
import '../use_cases/canvas/export_image_params.dart';

/// Repository for canvas drawing operations and project persistence.
abstract class CanvasRepository {
  /// Adds a new stroke to the project.
  Future<void> addStroke(String projectId, StrokeEntity stroke);

  /// Saves the project locally and schedules cloud sync.
  Future<void> saveProject(ProjectEntity project);

  /// Loads a project for the given contour.
  Future<ProjectEntity?> loadProject(String contourId);

  /// Exports the project as an image and returns the file path.
  Future<String?> exportImage(ExportImageParams params);

  /// Saves the exported image at [filePath] to the device gallery.
  Future<void> saveImageToGallery(String filePath);
}
