part of 'canvas_bloc.dart';

/// Base class for canvas events.
abstract class CanvasEvent extends Equatable {
  /// Creates a [CanvasEvent].
  const CanvasEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Loads a project for the given contour.
class LoadProject extends CanvasEvent {
  /// Creates a [LoadProject] event.
  const LoadProject();
}

/// Starts a new stroke.
class StartDrawing extends CanvasEvent {
  /// Starting point.
  final Offset point;

  /// Pressure value from the stylus (0.0 - 1.0).
  final double pressure;

  /// Creates a [StartDrawing] event.
  const StartDrawing({required this.point, this.pressure = 1.0});

  @override
  List<Object?> get props => <Object?>[point, pressure];
}

/// Adds a point to the current stroke.
class AddPoint extends CanvasEvent {
  /// New point.
  final Offset point;

  /// Pressure value from the stylus.
  final double pressure;

  /// Creates an [AddPoint] event.
  const AddPoint({required this.point, this.pressure = 1.0});

  @override
  List<Object?> get props => <Object?>[point, pressure];
}

/// Ends the current stroke.
class EndDrawing extends CanvasEvent {
  /// Creates an [EndDrawing] event.
  const EndDrawing();
}

/// Cancels the current stroke and removes it without saving.
class CancelDrawing extends CanvasEvent {
  /// Creates a [CancelDrawing] event.
  const CancelDrawing();
}

/// Undoes the last stroke.
class Undo extends CanvasEvent {
  /// Creates an [Undo] event.
  const Undo();
}

/// Redoes the previously undone stroke.
class Redo extends CanvasEvent {
  /// Creates a [Redo] event.
  const Redo();
}

/// Saves the project.
class SaveProject extends CanvasEvent {
  /// Creates a [SaveProject] event.
  const SaveProject();
}

/// Export destination type.
enum ExportType {
  /// Share the exported image via the platform share sheet.
  share,

  /// Save the exported image to the device gallery.
  gallery,
}

/// Exports the project as an image.
class ExportImage extends CanvasEvent {
  /// Export destination.
  final ExportType exportType;

  /// Path to a pre-captured canvas image. When null, the image is
  /// rendered from strokes and contour data.
  final String? filePath;

  /// Creates an [ExportImage] event for the given [exportType].
  const ExportImage(this.exportType, {this.filePath});

  @override
  List<Object?> get props => <Object?>[exportType, filePath];
}

/// Notifies that the export operation has finished.
class ExportImageFinished extends CanvasEvent {
  /// Path to the exported image file, or null if export failed.
  final String? filePath;

  /// Export destination that was used.
  final ExportType? exportType;

  /// Creates an [ExportImageFinished] event.
  const ExportImageFinished({this.filePath, this.exportType});

  @override
  List<Object?> get props => <Object?>[filePath, exportType];
}

/// Changes the brush size.
class ChangeBrushSize extends CanvasEvent {
  /// New brush size.
  final double size;

  /// Creates a [ChangeBrushSize] event.
  const ChangeBrushSize(this.size);

  @override
  List<Object?> get props => <Object?>[size];
}

/// Changes the brush opacity.
class ChangeOpacity extends CanvasEvent {
  /// New opacity.
  final double opacity;

  /// Creates a [ChangeOpacity] event.
  const ChangeOpacity(this.opacity);

  @override
  List<Object?> get props => <Object?>[opacity];
}

/// Changes the brush color.
class ChangeColor extends CanvasEvent {
  /// New color.
  final Color color;

  /// Creates a [ChangeColor] event.
  const ChangeColor(this.color);

  @override
  List<Object?> get props => <Object?>[color];
}

/// Changes the brush type.
class ChangeBrushType extends CanvasEvent {
  /// New brush type.
  final BrushType brushType;

  /// Creates a [ChangeBrushType] event.
  const ChangeBrushType(this.brushType);

  @override
  List<Object?> get props => <Object?>[brushType];
}

/// Changes contour display settings.
class ChangeContourSettings extends CanvasEvent {
  /// New contour color.
  final Color? color;

  /// New contour opacity.
  final double? opacity;

  /// New contour width.
  final double? width;

  /// Creates a [ChangeContourSettings] event.
  const ChangeContourSettings({this.color, this.opacity, this.width});

  @override
  List<Object?> get props => <Object?>[color, opacity, width];
}

/// Resets the canvas view transformation.
class ResetView extends CanvasEvent {
  /// Creates a [ResetView] event.
  const ResetView();
}

/// Applies a view transformation.
class UpdateTransform extends CanvasEvent {
  /// Transformation matrix.
  final Matrix4 transform;

  /// Creates an [UpdateTransform] event.
  const UpdateTransform(this.transform);

  @override
  List<Object?> get props => <Object?>[transform];
}

/// Toggles eraser mode.
class ToggleEraser extends CanvasEvent {
  /// Creates a [ToggleEraser] event.
  const ToggleEraser();
}

/// Available canvas tools.
enum CanvasTool {
  /// Standard brush for drawing.
  brush,

  /// Eraser for removing strokes.
  eraser,
}

/// Selects a drawing tool.
class SelectTool extends CanvasEvent {
  /// The tool to select.
  final CanvasTool tool;

  /// Creates a [SelectTool] event.
  const SelectTool(this.tool);

  @override
  List<Object?> get props => <Object?>[tool];
}
