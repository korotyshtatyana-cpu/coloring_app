import 'dart:async';
import 'dart:math';

import 'package:core/core.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

part 'canvas_event.dart';
part 'canvas_state.dart';

/// BLoC responsible for canvas drawing state and tool settings.
class CanvasBloc extends Bloc<CanvasEvent, CanvasState> {
  final String _contourId;
  final AddStrokeUseCase _addStrokeUseCase;
  final SaveProjectUseCase _saveProjectUseCase;
  final LoadProjectUseCase _loadProjectUseCase;
  final GetContourByIdUseCase _getContourByIdUseCase;
  final ExportImageUseCase _exportImageUseCase;
  final ShareFileUseCase _shareFileUseCase;
  final SaveImageToGalleryUseCase _saveImageToGalleryUseCase;

  Timer? _autosaveTimer;

  /// Creates a [CanvasBloc] with required dependencies.
  CanvasBloc({
    required this._contourId,
    required this._addStrokeUseCase,
    required this._saveProjectUseCase,
    required this._loadProjectUseCase,
    required this._getContourByIdUseCase,
    required this._exportImageUseCase,
    required this._shareFileUseCase,
    required this._saveImageToGalleryUseCase,
  })  : super(CanvasState()) {
    on<LoadProject>(_onLoadProject);
    on<StartDrawing>(_onStartDrawing);
    on<AddPoint>(_onAddPoint);
    on<EndDrawing>(_onEndDrawing);
    on<Undo>(_onUndo);
    on<Redo>(_onRedo);
    on<SaveProject>(_onSaveProject);
    on<ChangeBrushSize>(_onChangeBrushSize);
    on<ChangeOpacity>(_onChangeOpacity);
    on<ChangeColor>(_onChangeColor);
    on<ChangeBrushType>(_onChangeBrushType);
    on<ChangeContourSettings>(_onChangeContourSettings);
    on<ResetView>(_onResetView);
    on<UpdateTransform>(_onUpdateTransform);
    on<ToggleEraser>(_onToggleEraser);
    on<SelectTool>(_onSelectTool);
    on<ExportImage>(_onExportImage);
    on<ExportImageFinished>(_onExportImageFinished);
  }

  Future<void> _onLoadProject(
    LoadProject event,
    Emitter<CanvasState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CanvasStatus.loading, error: null));

      final contour = await _getContourByIdUseCase.execute(_contourId);
      final project = await _loadProjectUseCase.execute(_contourId);
      final strokes = project == null
          ? <StrokeEntity>[]
          : _strokesFromData(project.data);

      emit(state.copyWith(
        status: CanvasStatus.ready,
        contour: contour,
        strokes: strokes,
        undoStack: strokes,
        redoStack: const <StrokeEntity>[],
      ));
    } catch (e, stackTrace) {
      ErrorHandler.report(e, stackTrace);
      emit(state.copyWith(
        status: CanvasStatus.error,
        error: e.toString(),
      ));
    }
  }

  void _onStartDrawing(
    StartDrawing event,
    Emitter<CanvasState> emit,
  ) {
    final effectiveSize = _effectiveSize(event.pressure);
    final stroke = StrokeEntity(
      points: <Offset>[event.point],
      color: state.isEraser ? Colors.white.toARGB32() : state.color.toARGB32(),
      size: state.isEraser ? effectiveSize * 2 : effectiveSize,
      opacity: state.isEraser ? 1.0 : state.opacity,
      brushType: state.isEraser ? BrushType.circle : state.brushType,
    );
    final strokes = <StrokeEntity>[...state.strokes, stroke];
    final undoStack = <StrokeEntity>[...state.undoStack, stroke];
    if (undoStack.length > Constants.maxUndoSteps) {
      undoStack.removeAt(0);
    }
    emit(state.copyWith(
      status: CanvasStatus.drawing,
      strokes: strokes,
      currentStroke: stroke,
      undoStack: undoStack,
      redoStack: const <StrokeEntity>[],
    ));
  }

  void _onAddPoint(
    AddPoint event,
    Emitter<CanvasState> emit,
  ) {
    if (state.currentStroke == null || state.strokes.isEmpty) return;

    final effectiveSize = _effectiveSize(event.pressure);
    final updated = state.currentStroke!.copyWith(
      points: <Offset>[...state.currentStroke!.points, event.point],
      size: effectiveSize,
    );
    final strokes = List<StrokeEntity>.from(state.strokes);
    strokes[strokes.length - 1] = updated;
    final undoStack = List<StrokeEntity>.from(state.undoStack);
    undoStack[undoStack.length - 1] = updated;

    emit(state.copyWith(
      strokes: strokes,
      undoStack: undoStack,
      currentStroke: updated,
    ));
  }

  Future<void> _onEndDrawing(
    EndDrawing event,
    Emitter<CanvasState> emit,
  ) async {
    if (state.currentStroke == null) return;

    final strokeToSave = state.currentStroke!;
    final shouldSave = state.strokes.isNotEmpty && state.strokes.last == strokeToSave;

    final undoStack = List<StrokeEntity>.from(state.undoStack);
    if (undoStack.isNotEmpty) {
      undoStack[undoStack.length - 1] = strokeToSave;
    }

    emit(state.copyWith(
      status: CanvasStatus.ready,
      currentStroke: null,
      undoStack: undoStack,
    ));

    if (!shouldSave) return;

    try {
      await _addStrokeUseCase.execute(
        AddStrokeParams(
          projectId: _contourId,
          stroke: strokeToSave,
        ),
      );
      _scheduleAutosave();
    } catch (e, stackTrace) {
      ErrorHandler.report(e, stackTrace);
    }
  }

  Future<void> _onUndo(Undo event, Emitter<CanvasState> emit) async {
    if (state.undoStack.isEmpty) return;

    final removed = state.undoStack.last;
    final isCurrentStroke =
        state.currentStroke != null && state.currentStroke == removed;
    final undoStack = List<StrokeEntity>.from(state.undoStack)..removeLast();
    final strokes = List<StrokeEntity>.from(state.strokes)..removeLast();
    final redoStack = <StrokeEntity>[removed, ...state.redoStack];

    emit(state.copyWith(
      status: isCurrentStroke ? CanvasStatus.ready : state.status,
      strokes: strokes,
      undoStack: undoStack,
      redoStack: redoStack,
      currentStroke: isCurrentStroke ? null : state.currentStroke,
    ));

    _scheduleAutosave();
  }

  Future<void> _onRedo(Redo event, Emitter<CanvasState> emit) async {
    if (state.redoStack.isEmpty) return;

    final restored = state.redoStack.first;
    final redoStack = List<StrokeEntity>.from(state.redoStack)..removeAt(0);
    final strokes = <StrokeEntity>[...state.strokes, restored];
    final undoStack = <StrokeEntity>[...state.undoStack, restored];
    if (undoStack.length > Constants.maxUndoSteps) {
      undoStack.removeAt(0);
    }

    emit(state.copyWith(
      strokes: strokes,
      undoStack: undoStack,
      redoStack: redoStack,
    ));

    _scheduleAutosave();
  }

  Future<void> _onSaveProject(
    SaveProject event,
    Emitter<CanvasState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CanvasStatus.saving));
      await _saveProjectUseCase.execute(_projectEntity());
      emit(state.copyWith(status: CanvasStatus.ready));
    } catch (e, stackTrace) {
      ErrorHandler.report(e, stackTrace);
      emit(state.copyWith(
        status: CanvasStatus.error,
        error: e.toString(),
      ));
    }
  }

  void _onChangeBrushSize(
    ChangeBrushSize event,
    Emitter<CanvasState> emit,
  ) {
    emit(state.copyWith(
      brushSize: event.size.clamp(Constants.minBrushSize, Constants.maxBrushSize),
    ));
  }

  void _onChangeOpacity(
    ChangeOpacity event,
    Emitter<CanvasState> emit,
  ) {
    emit(state.copyWith(opacity: event.opacity.clamp(0.0, 1.0)));
  }

  void _onChangeColor(ChangeColor event, Emitter<CanvasState> emit) {
    emit(state.copyWith(color: event.color));
  }

  void _onChangeBrushType(
    ChangeBrushType event,
    Emitter<CanvasState> emit,
  ) {
    emit(state.copyWith(brushType: event.brushType));
  }

  void _onChangeContourSettings(
    ChangeContourSettings event,
    Emitter<CanvasState> emit,
  ) {
    emit(state.copyWith(
      contourColor: event.color ?? state.contourColor,
      contourOpacity: event.opacity ?? state.contourOpacity,
      contourWidth: event.width ?? state.contourWidth,
    ));
  }

  void _onResetView(ResetView event, Emitter<CanvasState> emit) {
    emit(state.copyWith(transform: Matrix4.identity()));
  }

  void _onUpdateTransform(
    UpdateTransform event,
    Emitter<CanvasState> emit,
  ) {
    emit(state.copyWith(transform: event.transform));
  }

  void _onToggleEraser(ToggleEraser event, Emitter<CanvasState> emit) {
    emit(state.copyWith(isEraser: !state.isEraser));
  }

  void _onSelectTool(SelectTool event, Emitter<CanvasState> emit) {
    emit(state.copyWith(isEraser: event.tool == CanvasTool.eraser));
  }

  Future<void> _onExportImage(
    ExportImage event,
    Emitter<CanvasState> emit,
  ) async {
    if (state.contour == null) return;

    try {
      emit(state.copyWith(status: CanvasStatus.exporting, error: null));

      final filePath = await _exportImageUseCase.execute(
        ExportImageParams(
          projectId: state.contour!.id,
          contourSvg: state.contour!.svgData,
          contourColor: state.contourColor,
          contourOpacity: state.contourOpacity,
          contourWidth: state.contourWidth,
        ),
      );

      if (filePath == null) {
        emit(state.copyWith(status: CanvasStatus.error, error: 'Export failed'));
        return;
      }

      switch (event.exportType) {
        case ExportType.share:
          await _shareFileUseCase.execute(filePath);
        case ExportType.gallery:
          await _saveImageToGalleryUseCase.execute(filePath);
      }

      add(ExportImageFinished(filePath: filePath));
    } catch (e, stackTrace) {
      ErrorHandler.report(e, stackTrace);
      emit(state.copyWith(status: CanvasStatus.error, error: e.toString()));
    }
  }

  void _onExportImageFinished(
    ExportImageFinished event,
    Emitter<CanvasState> emit,
  ) {
    emit(state.copyWith(
      status: CanvasStatus.ready,
      exportedFilePath: event.filePath,
    ));
  }

  double _effectiveSize(double pressure) {
    final clamped = pressure.clamp(0.0, 1.0);
    return max(Constants.minBrushSize, state.brushSize * clamped);
  }

  ProjectEntity _projectEntity() {
    return ProjectEntity(
      id: _contourId,
      contourId: _contourId,
      userId: '',
      data: <String, dynamic>{
        'strokes': state.strokes.asMap().entries.map((MapEntry<int, StrokeEntity> entry) {
          final StrokeEntity stroke = entry.value;
          return <String, dynamic>{
            'id': '${_contourId}_${entry.key}',
            'project_id': _contourId,
            'points': stroke.points
                .map((Offset p) => <double>[p.dx, p.dy])
                .toList(),
            'color': stroke.color,
            'size': stroke.size,
            'opacity': stroke.opacity,
            'brushType': stroke.brushType.name,
          };
        }).toList(),
        'settings': <String, dynamic>{
          'contourColor': state.contourColor.toARGB32(),
          'contourOpacity': state.contourOpacity,
          'contourWidth': state.contourWidth,
        },
      },
      lastOpened: DateTime.now(),
      createdAt: DateTime.now(),
    );
  }

  List<StrokeEntity> _strokesFromData(Map<String, dynamic> data) {
    final strokesJson = data['strokes'] as List<dynamic>?;
    if (strokesJson == null) return <StrokeEntity>[];

    return strokesJson.map((dynamic json) {
      final map = json as Map<String, dynamic>;
      return StrokeEntity(
        points: (map['points'] as List<dynamic>)
            .map((dynamic row) {
              final list = row as List<dynamic>;
              return Offset(list[0] as double, list[1] as double);
            })
            .toList(),
        color: map['color'] as int,
        size: (map['size'] as num).toDouble(),
        opacity: (map['opacity'] as num).toDouble(),
        brushType: BrushType.values.byName(map['brushType'] as String),
      );
    }).toList();
  }

  void _scheduleAutosave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(Constants.autosaveDebounce, () {
      add(const SaveProject());
    });
  }

  @override
  Future<void> close() {
    _autosaveTimer?.cancel();
    return super.close();
  }
}
