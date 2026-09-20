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
  final RenderProjectThumbnailUseCase _renderProjectThumbnailUseCase;
  final GetAvailableToolsUseCase _getAvailableToolsUseCase;

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
    required this._renderProjectThumbnailUseCase,
    required this._getAvailableToolsUseCase,
  })  : super(CanvasState()) {
    on<LoadProject>(_onLoadProject);
    on<StartDrawing>(_onStartDrawing);
    on<AddPoint>(_onAddPoint);
    on<EndDrawing>(_onEndDrawing);
    on<CancelDrawing>(_onCancelDrawing);
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
    on<SelectBrush>(_onSelectBrush);
    on<SelectEraser>(_onSelectEraser);
    on<ClearProject>(_onClearProject);
    on<ExportImage>(_onExportImage);
    on<ExportImageFinished>(_onExportImageFinished);
    on<ContourCompiled>(_onContourCompiled);
  }

  Future<void> _onLoadProject(
    LoadProject event,
    Emitter<CanvasState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CanvasStatus.loading, error: null));

      // 1. Fetch available tools from DB
      final allTools = await _getAvailableToolsUseCase.execute();

      // 2. Load contour and project data
      final contour = await _getContourByIdUseCase.execute(_contourId);
      final project = await _loadProjectUseCase.execute(_contourId);
      final strokes = project == null
          ? <StrokeEntity>[]
          : _strokesFromData(project.data);

      final settings = project?.data['settings'] as Map<String, dynamic>?;
      final Color? loadedColor = settings?['contourColor'] != null
          ? Color(settings!['contourColor'] as int)
          : null;
      final double? loadedOpacity = settings?['contourOpacity']?.toDouble();
      final String? thumbnailPath = project?.data['thumbnailPath'] as String?;

      Size? contourSize;
      String? contourSvg;
      if (contour != null) {
        contourSvg = await SvgUtils.fetchSvgContent(contour.svgUrl);
        if (contourSvg != null) {
          contourSize = SvgUtils.parseViewBoxSize(contourSvg);
        }
      }

      emit(state.copyWith(
        contour: contour,
        contourSize: contourSize,
        contourSvg: contourSvg,
        strokes: strokes,
        undoStack: strokes,
        redoStack: const <StrokeEntity>[],
        contourColor: loadedColor ?? state.contourColor,
        contourOpacity: loadedOpacity ?? state.contourOpacity,
        thumbnailPath: thumbnailPath,
        availableTools: allTools,
        activeBrushId: allTools.isNotEmpty ? allTools.first.id : null,
        activeEraserId: allTools.isNotEmpty ? allTools.first.id : null,
      ));

      // If the contour was not fetched correctly or doesn't exist, we don't
      // wait for compilation and switch to ready immediately.
      if (contourSvg == null) {
        emit(state.copyWith(
          status: CanvasStatus.ready,
          isContourReady: true,
        ));
      }

      // Automatically update last_opened timestamp when project is opened
      unawaited(saveProject(withThumbnail: false));
    } catch (e, stackTrace) {
      ErrorHandler.report(e, stackTrace);
      emit(state.copyWith(
        status: CanvasStatus.error,
        error: e.toString(),
      ));
    }
  }

  void _onContourCompiled(
    ContourCompiled event,
    Emitter<CanvasState> emit,
  ) {
    emit(state.copyWith(
      status: CanvasStatus.ready,
      isContourReady: true,
    ));
  }

  void _onStartDrawing(
    StartDrawing event,
    Emitter<CanvasState> emit,
  ) {
    final activeToolId = state.isEraser ? state.activeEraserId : state.activeBrushId;
    final activeTool = state.availableTools.firstWhere((t) => t.id == activeToolId);

    final isPressure = activeTool.isPressureSensitive;
    final effectiveSize = isPressure ? _effectiveSize(event.pressure) : state.brushSize;

    final stroke = StrokeEntity(
      points: <StrokePoint>[
        StrokePoint(offset: event.point, pressure: isPressure ? event.pressure : 1.0)
      ],
      color: state.isEraser ? Colors.white.toARGB32() : state.color.toARGB32(),
      size: state.isEraser ? effectiveSize : state.brushSize,
      opacity: state.isEraser ? 1.0 : state.opacity,
      brushType: state.isEraser ? BrushType.circle : state.brushType,
      brushId: activeToolId,
      isPressureSensitive: isPressure,
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

    final activeToolId = state.currentStroke!.brushId;
    final activeTool = state.availableTools.firstWhere((t) => t.id == activeToolId);
    final isPressure = activeTool.isPressureSensitive;

    final updated = state.currentStroke!.copyWith(
      points: <StrokePoint>[
        ...state.currentStroke!.points,
        StrokePoint(offset: event.point, pressure: isPressure ? event.pressure : 1.0),
      ],
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

  void _onSelectBrush(SelectBrush event, Emitter<CanvasState> emit) {
    emit(state.copyWith(activeBrushId: event.brushId, isEraser: false));
  }

  void _onSelectEraser(SelectEraser event, Emitter<CanvasState> emit) {
    emit(state.copyWith(activeEraserId: event.eraserId, isEraser: true));
  }

  Future<void> _onClearProject(
    ClearProject event,
    Emitter<CanvasState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CanvasStatus.saving));

      // 1. Clear strokes in state
      final newState = state.copyWith(
        strokes: const <StrokeEntity>[],
        undoStack: const <StrokeEntity>[],
        redoStack: const <StrokeEntity>[],
        thumbnailPath: null,
      );

      // 2. Persist the empty project (this clears local/remote strokes)
      await _saveProjectUseCase.execute(
        _projectEntity(state: newState, thumbnailPath: null),
      );

      emit(newState.copyWith(status: CanvasStatus.ready));
    } catch (e, stackTrace) {
      ErrorHandler.report(e, stackTrace);
      emit(state.copyWith(
        status: CanvasStatus.error,
        error: e.toString(),
      ));
    }
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

  void _onCancelDrawing(
    CancelDrawing event,
    Emitter<CanvasState> emit,
  ) {
    final StrokeEntity? current = state.currentStroke;
    if (current == null) return;

    final strokes = List<StrokeEntity>.from(state.strokes);
    if (strokes.isNotEmpty && strokes.last == current) {
      strokes.removeLast();
    }
    final undoStack = List<StrokeEntity>.from(state.undoStack);
    if (undoStack.isNotEmpty && undoStack.last == current) {
      undoStack.removeLast();
    }

    emit(state.copyWith(
      status: CanvasStatus.ready,
      strokes: strokes,
      undoStack: undoStack,
      clearCurrentStroke: true,
    ));
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
    await saveProject(withThumbnail: event.withThumbnail, emit: emit);
  }

  /// Saves the project, optionally re-rendering its thumbnail.
  ///
  /// Public so callers that must await completion (e.g. before popping the
  /// route) can invoke it directly. When [emit] is omitted (external
  /// callers), no status states are emitted.
  Future<void> saveProject({
    bool withThumbnail = true,
    Emitter<CanvasState>? emit,
  }) async {
    if (state.status == CanvasStatus.initial ||
        state.status == CanvasStatus.loading) {
      // Project not loaded yet: saving would clobber stored strokes.
      return;
    }

    try {
      if (!isClosed) emit?.call(state.copyWith(status: CanvasStatus.saving));

      String? thumbnailPath = state.thumbnailPath;
      if (withThumbnail && state.contour != null && state.contourSvg != null) {
        thumbnailPath = await _renderProjectThumbnailUseCase.execute(
              ExportImageParams(
                projectId: _contourId,
                contourSvg: state.contourSvg!,
                contourColor: state.contourColor,
                contourOpacity: state.contourOpacity,
                strokes: state.strokes,
              ),
            ) ??
            thumbnailPath;
      }

      await _saveProjectUseCase.execute(
        _projectEntity(thumbnailPath: thumbnailPath),
      );
      if (!isClosed) {
        emit?.call(state.copyWith(
          status: CanvasStatus.ready,
          thumbnailPath: thumbnailPath,
        ));
      }
    } catch (e, stackTrace) {
      ErrorHandler.report(e, stackTrace);
      if (!isClosed) {
        emit?.call(state.copyWith(
          status: CanvasStatus.error,
          error: e.toString(),
        ));
      }
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
    ));
    _scheduleAutosave();
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
    if (state.contour == null || state.contourSvg == null) return;

    try {
      emit(state.copyWith(status: CanvasStatus.exporting, error: null));

      final filePath = await _exportImageUseCase.execute(
        ExportImageParams(
          projectId: state.contour!.id,
          contourSvg: state.contourSvg!,
          contourColor: state.contourColor,
          contourOpacity: state.contourOpacity,
        ),
      );

      if (filePath == null) {
        emit(state.copyWith(
          status: CanvasStatus.error,
          error: LocaleKeys.export_failed.tr(),
        ));
        return;
      }

      switch (event.exportType) {
        case ExportType.share:
          await _shareFileUseCase.execute(filePath);
        case ExportType.gallery:
          await _saveImageToGalleryUseCase.execute(filePath);
      }

      add(ExportImageFinished(filePath: filePath, exportType: event.exportType));
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
      lastExportType: event.exportType,
    ));
  }

  double _effectiveSize(double pressure) {
    final clamped = pressure.clamp(0.0, 1.0);
    return max(Constants.minBrushSize, state.brushSize * clamped);
  }

  ProjectEntity _projectEntity({CanvasState? state, String? thumbnailPath}) {
    final effectiveState = state ?? this.state;
    return ProjectEntity(
      id: _contourId,
      contourId: _contourId,
      userId: '',
      data: <String, dynamic>{
        'strokes': effectiveState.strokes.asMap().entries.map((MapEntry<int, StrokeEntity> entry) {
          final StrokeEntity stroke = entry.value;
          return <String, dynamic>{
            'id': '${_contourId}_${entry.key}',
            'project_id': _contourId,
            'points': stroke.points
                .map((StrokePoint p) =>
                    <double>[p.offset.dx, p.offset.dy, p.pressure])
                .toList(),
            'color': stroke.color,
            'size': stroke.size,
            'opacity': stroke.opacity,
            'brushType': stroke.brushType.name,
            'brushId': stroke.brushId,
          };
        }).toList(),
        'settings': <String, dynamic>{
          'contourColor': effectiveState.contourColor.toARGB32(),
          'contourOpacity': effectiveState.contourOpacity,
        },
        if (thumbnailPath != null) 'thumbnailPath': thumbnailPath,
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
              return StrokePoint(
                offset: Offset(list[0] as double, list[1] as double),
                pressure: list.length > 2 ? list[2] as double : 1.0,
              );
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
      add(const SaveProject(withThumbnail: false));
    });
  }

  @override
  Future<void> close() {
    _autosaveTimer?.cancel();
    return super.close();
  }
}
