part of 'canvas_bloc.dart';

/// Canvas status values.
enum CanvasStatus {
  /// Initial state.
  initial,

  /// Loading project data.
  loading,

  /// Canvas ready for drawing.
  ready,

  /// Drawing in progress.
  drawing,

  /// Saving project.
  saving,

  /// Exporting image.
  exporting,

  /// Error state.
  error,
}

/// State of the canvas feature.
class CanvasState extends Equatable {
  /// Current canvas status.
  final CanvasStatus status;

  /// All committed strokes.
  final List<StrokeEntity> strokes;

  /// Stroke currently being drawn.
  final StrokeEntity? currentStroke;

  /// Loaded contour to render on top.
  final ContourEntity? contour;

  /// History of strokes for undo.
  final List<StrokeEntity> undoStack;

  /// Strokes that were undone and can be redone.
  final List<StrokeEntity> redoStack;

  /// Current brush size.
  final double brushSize;

  /// Current brush opacity.
  final double opacity;

  /// Current brush color.
  final Color color;

  /// Current brush type.
  final BrushType brushType;

  /// Whether eraser is active.
  final bool isEraser;

  /// Contour display color.
  final Color contourColor;

  /// Contour display opacity.
  final double contourOpacity;

  /// Contour display width.
  final double contourWidth;

  /// Canvas transformation matrix.
  final Matrix4 transform;

  /// Path to the most recently exported image file.
  final String? exportedFilePath;

  /// Destination of the most recent export.
  final ExportType? lastExportType;

  /// Path to the rendered project thumbnail, if any.
  final String? thumbnailPath;

  /// Error message, if any.
  final String? error;

  /// Creates a [CanvasState].
  CanvasState({
    this.status = CanvasStatus.initial,
    this.strokes = const <StrokeEntity>[],
    this.currentStroke,
    this.contour,
    this.undoStack = const <StrokeEntity>[],
    this.redoStack = const <StrokeEntity>[],
    this.brushSize = Constants.defaultBrushSize,
    this.opacity = Constants.defaultOpacity,
    this.color = Colors.black,
    this.brushType = BrushType.circle,
    this.isEraser = false,
    this.contourColor = Colors.black,
    this.contourOpacity = Constants.contourDefaultOpacity,
    this.contourWidth = Constants.contourDefaultWidth,
    Matrix4? transform,
    this.exportedFilePath,
    this.lastExportType,
    this.thumbnailPath,
    this.error,
  }) : transform = transform ?? Matrix4.identity();

  @override
  List<Object?> get props => <Object?>[
        status,
        strokes,
        currentStroke,
        contour,
        undoStack,
        redoStack,
        brushSize,
        opacity,
        color,
        brushType,
        isEraser,
        contourColor,
        contourOpacity,
        contourWidth,
        transform,
        exportedFilePath,
        lastExportType,
        thumbnailPath,
        error,
      ];

  /// Creates a copy with optional new values.
  CanvasState copyWith({
    CanvasStatus? status,
    List<StrokeEntity>? strokes,
    StrokeEntity? currentStroke,
    bool clearCurrentStroke = false,
    ContourEntity? contour,
    List<StrokeEntity>? undoStack,
    List<StrokeEntity>? redoStack,
    double? brushSize,
    double? opacity,
    Color? color,
    BrushType? brushType,
    bool? isEraser,
    Color? contourColor,
    double? contourOpacity,
    double? contourWidth,
    Matrix4? transform,
    String? exportedFilePath,
    ExportType? lastExportType,
    String? thumbnailPath,
    String? error,
  }) {
    return CanvasState(
      status: status ?? this.status,
      strokes: strokes ?? this.strokes,
      currentStroke: clearCurrentStroke ? null : currentStroke ?? this.currentStroke,
      contour: contour ?? this.contour,
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
      brushSize: brushSize ?? this.brushSize,
      opacity: opacity ?? this.opacity,
      color: color ?? this.color,
      brushType: brushType ?? this.brushType,
      isEraser: isEraser ?? this.isEraser,
      contourColor: contourColor ?? this.contourColor,
      contourOpacity: contourOpacity ?? this.contourOpacity,
      contourWidth: contourWidth ?? this.contourWidth,
      transform: transform ?? this.transform,
      exportedFilePath: exportedFilePath ?? this.exportedFilePath,
      lastExportType: lastExportType ?? this.lastExportType,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      error: error ?? this.error,
    );
  }
}
