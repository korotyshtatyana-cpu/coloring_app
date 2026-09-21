import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../bloc/canvas_bloc.dart';
import '../widgets/canvas/active_stroke.dart';
import '../widgets/canvas/canvas_stack.dart';
import '../widgets/eyedropper_overlay.dart';
import '../widgets/export_menu.dart';
import '../widgets/toolbars/bottom_toolbar.dart';
import '../widgets/toolbars/left_controls.dart';
import '../widgets/toolbars/top_toolbar.dart';

/// Canvas screen for drawing and coloring a contour.
@RoutePage()
class CanvasScreen extends StatelessWidget {
  /// Identifier of the contour being colored.
  final String contourId;

  final GlobalKey<_CanvasContentState> _canvasKey =
      GlobalKey<_CanvasContentState>();

  /// Creates a [CanvasScreen].
  CanvasScreen({super.key, required this.contourId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CanvasBloc>(
      create: (context) => CanvasBloc(
        contourId: contourId,
        addStrokeUseCase: appLocator<AddStrokeUseCase>(),
        saveProjectUseCase: appLocator<SaveProjectUseCase>(),
        loadProjectUseCase: appLocator<LoadProjectUseCase>(),
        getContourByIdUseCase: appLocator<GetContourByIdUseCase>(),
        exportImageUseCase: appLocator<ExportImageUseCase>(),
        shareFileUseCase: appLocator<ShareFileUseCase>(),
        saveImageToGalleryUseCase: appLocator<SaveImageToGalleryUseCase>(),
        renderProjectThumbnailUseCase:
            appLocator<RenderProjectThumbnailUseCase>(),
        getAvailableToolsUseCase: appLocator<GetAvailableToolsUseCase>(),
      )..add(const LoadProject()),
      child: CanvasContent(
        key: _canvasKey,
        onExport: () => _canvasKey.currentState?.showExportMenu(),
        onEyedropper: ({required bool isContour}) =>
            _canvasKey.currentState?.enterEyedropperMode(isContour: isContour),
      ),
    );
  }
}

class CanvasContent extends StatefulWidget {
  /// Callback invoked when the user taps the export button.
  final VoidCallback onExport;

  /// Callback invoked when the eyedropper mode is requested.
  final void Function({required bool isContour}) onEyedropper;

  /// Creates [CanvasContent].
  const CanvasContent({
    required this.onExport,
    required this.onEyedropper,
    super.key,
  });

  @override
  State<CanvasContent> createState() => _CanvasContentState();
}

class _CanvasContentState extends State<CanvasContent>
    with WidgetsBindingObserver {
  final TransformationController _transformationController =
      TransformationController();
  final GlobalKey _repaintKey = GlobalKey();

  /// High-performance holder for the active stroke to avoid BLoC rebuilds
  /// and O(n) per-event copies while drawing.
  final ActiveStroke _activeStroke = ActiveStroke();

  bool _isEyedropperActive = false;

  /// Pointer currently being used by the eyedropper, if any.
  int? _eyedropperPointer;

  /// Current viewport position of the eyedropper pointer.
  Offset? _eyedropperPosition;

  /// Color currently previewed by the eyedropper.
  Color? _previewColor;

  /// Whether the final save (with thumbnail) is running before the screen
  /// closes. While true, a progress overlay is shown.
  bool _isSavingBeforeClose = false;

  /// Whether the pop was already requested after the save finished.
  /// Prevents re-entering the save when the router triggers the pop-scope
  /// callback again while the route is being removed.
  bool _popped = false;

  /// Cached canvas image used while dragging the eyedropper.
  ui.Image? _eyedropperImage;

  /// Byte data of [_eyedropperImage] for fast pixel reads.
  ByteData? _eyedropperByteData;

  /// Future for the in-progress eyedropper image capture, if any.
  Future<void>? _eyedropperCaptureFuture;

  /// Whether the eyedropper was triggered for the contour or the brush.
  bool _isEyedropperForContour = false;

  /// Active pointers currently on screen (viewport coordinates).
  final Map<int, Offset> _pointerPositions = <int, Offset>{};

  /// Pointer positions captured when the two-finger gesture started.
  Map<int, Offset>? _initialPointerPositions;

  /// Transform value when the two-finger gesture started.
  Matrix4? _initialTransform;

  /// Pointer that is currently drawing, if any.
  int? _activeDrawPointer;

  /// Whether a multi-touch (pinch) gesture is in progress or just finished.
  /// While true, drawing is suppressed until all fingers are lifted.
  bool _drawingLocked = false;

  /// Viewport size seen on the last [build]; used to detect orientation
  /// (or window size) changes and recenter the canvas.
  Size? _lastViewportSize;

  static const double _minScaleFactor = 0.5; // relative to the fit scale
  static const double _maxScaleFactor = 5.0; // relative to the fit scale
  static const double _boundaryMargin = 64.0;

  /// Margin around the canvas sheet when fitting it into the viewport.
  static const EdgeInsets _canvasPadding = EdgeInsets.only(
    top: 120,
    right: 16,
    bottom: 64,
    left: 16,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _transformationController.dispose();
    _activeStroke.dispose();
    _disposeEyedropperImage();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Background saves should only persist data, not re-render UI.
      context.read<CanvasBloc>().add(const SaveProject(withThumbnail: false));
    }
  }

  /// Runs the final save (with thumbnail) and closes the screen afterwards.
  ///
  /// Awaiting the save before popping guarantees that the gallery reads the
  /// fresh thumbnail when it reloads. On failure the screen still closes —
  /// the latest strokes were already persisted by autosave.
  Future<void> _saveAndPop() async {
    if (_isSavingBeforeClose || _popped) return;
    setState(() => _isSavingBeforeClose = true);

    final CanvasBloc bloc = context.read<CanvasBloc>();
    try {
      await bloc.saveProject(withThumbnail: true);
    } finally {
      if (mounted) {
        setState(() => _isSavingBeforeClose = false);
        _popped = true;
        // Use pop() (not maybePop) so the route closes unconditionally:
        // maybePop() goes through the PopScope again and can silently fail
        // when called after the async gap.
        context.router.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size viewportSize = MediaQuery.sizeOf(context);
    final state = context.watch<CanvasBloc>().state;
    final status = state.status;

    final bool isInitial = status == CanvasStatus.initial;
    final bool isLoading =
        (status == CanvasStatus.loading || !state.isContourReady) &&
        status != CanvasStatus.error;
    final AppColors colors = AppColors.of(context);

    final Size canvasSize = state.contourSize ?? viewportSize;
    final double fitScale = _fitScaleFor(viewportSize, canvasSize);

    if (_lastViewportSize != viewportSize) {
      final bool hadViewportSize = _lastViewportSize != null;
      _lastViewportSize = viewportSize;
      if (hadViewportSize) {
        // The viewport size changed (e.g. screen rotation): the stored
        // transform was computed for the old size, so recenter the canvas
        // once the frame with the new size is laid out.
        WidgetsBinding.instance.addPostFrameCallback((_) => _recenterCanvas());
      }
    }

    return PopScope(
      // Back navigation is triggered explicitly from the toolbar (reliable
      // on all devices). This is only a fallback for the system back
      // gesture: while the final save runs, pops are blocked; once the save
      // finished and the pop was requested, the route is allowed to pop.
      canPop: _popped,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        _saveAndPop();
      },
      child: Scaffold(
        body: MultiBlocListener(
          listeners: [
            BlocListener<CanvasBloc, CanvasState>(
              listenWhen: (CanvasState previous, CanvasState current) =>
                  previous.exportedFilePath != current.exportedFilePath &&
                  current.lastExportType == ExportType.gallery,
              listener: (context, state) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      LocaleKeys.saved_to_gallery.tr(),
                      style: AppFonts.normal16.copyWith(color: Colors.white),
                    ),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
            BlocListener<CanvasBloc, CanvasState>(
              listenWhen: (CanvasState previous, CanvasState current) =>
                  previous.status != current.status ||
                  previous.transform != current.transform ||
                  previous.contourSize != current.contourSize,
              listener: (context, state) {
                final Matrix4 transform = state.transform;
                if (transform.isIdentity()) {
                  // Identity means "no user transform": fit the canvas sheet
                  // into the viewport.
                  final Size viewport = MediaQuery.sizeOf(context);
                  final Size? svgSize = state.contourSize;
                  _transformationController.value = _fitTransform(
                    viewport,
                    svgSize ?? viewport,
                  );
                } else {
                  _transformationController.value = transform;
                }

                if (state.status == CanvasStatus.error) {
                  ErrorDialog.show(
                    context,
                    message:
                        state.error ?? LocaleKeys.something_went_wrong.tr(),
                  );
                }
              },
            ),
          ],
          child: Stack(
            children: <Widget>[
              if (!isInitial)
                Positioned.fill(
                  child: RepaintBoundary(
                    key: _repaintKey,
                    child: InteractiveViewer(
                      transformationController: _transformationController,
                      constrained: false,
                      boundaryMargin: const EdgeInsets.all(_boundaryMargin),
                      minScale: fitScale * _minScaleFactor,
                      maxScale: fitScale * _maxScaleFactor,
                      panEnabled: false,
                      scaleEnabled: false,
                      child: SizedBox(
                        width: canvasSize.width,
                        height: canvasSize.height,
                        child: CanvasStack(
                          currentStrokeNotifier: _activeStroke,
                          canvasSize: canvasSize,
                        ),
                      ),
                    ),
                  ),
                ),
              if (isLoading)
                Positioned.fill(
                  child: ColoredBox(
                    color: colors.primaryBg,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: colors.accentDark,
                      ),
                    ),
                  ),
                ),
              Positioned.fill(
                child: Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: (event) => _onPointerDown(event, canvasSize),
                  onPointerMove: (event) => _onPointerMove(event, canvasSize),
                  onPointerUp: _onPointerUp,
                  onPointerCancel: _onPointerCancel,
                  child: Container(color: Colors.transparent),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: TopToolbar(
                  onExport: widget.onExport,
                  onBack: _saveAndPop,
                ),
              ),
              const Positioned(left: 8, top: 120, child: LeftControls()),
              Positioned(
                right: 8,
                bottom: 8,
                child: BottomToolbar(onEyedropper: widget.onEyedropper),
              ),
              if (_eyedropperPosition != null && _previewColor != null)
                BlocBuilder<CanvasBloc, CanvasState>(
                  buildWhen: (CanvasState previous, CanvasState current) =>
                      previous.color != current.color,
                  builder: (BuildContext context, CanvasState state) {
                    return EyedropperOverlay(
                      position: _eyedropperPosition!,
                      previewColor: _previewColor!,
                      selectedColor: state.color,
                      image: _eyedropperImage,
                    );
                  },
                ),
              if (_isSavingBeforeClose)
                Positioned.fill(
                  child: ColoredBox(
                    color: colors.black.withValues(alpha: 0.45),
                    child: Center(
                      child: CircularProgressIndicator(color: colors.primaryBg),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _onPointerDown(PointerDownEvent event, Size canvasSize) {
    _pointerPositions[event.pointer] = event.localPosition;

    if (_pointerPositions.length >= 2) {
      // Multiple pointers: stop drawing and switch to pan/zoom.
      _drawingLocked = true;
      if (_activeDrawPointer != null) {
        if (!_isEyedropperActive) {
          final StrokeEntity? stroke = _activeStroke.stroke;
          if (stroke != null && _isDotStroke(stroke)) {
            // Cancel drawing locally
            _activeStroke.clear();
          } else {
            _finalizeDrawing();
          }
        }
        _activeDrawPointer = null;
      }
      _resetTwoFingerGesture();
      return;
    }

    if (_canDrawWithPointer(event) && !_drawingLocked) {
      if (_isEyedropperActive) {
        _startEyedropperDrag(event.pointer, event.localPosition);
        return;
      }

      _activeDrawPointer = event.pointer;
      if (_isPointerOnCanvas(event.localPosition, canvasSize)) {
        _startDrawingLocally(
          _viewportToScene(event.localPosition),
          event.pressure,
        );
      }
    }
  }

  void _onPointerMove(PointerMoveEvent event, Size canvasSize) {
    if (!_pointerPositions.containsKey(event.pointer)) {
      return;
    }
    _pointerPositions[event.pointer] = event.localPosition;

    if (_isEyedropperActive) {
      if (event.pointer == _eyedropperPointer) {
        _updateEyedropperPosition(event.localPosition);
      }
      return;
    }

    if (_pointerPositions.length == 2 &&
        _initialPointerPositions != null &&
        _initialTransform != null) {
      _handleTwoFingerGesture(canvasSize);
    } else if (event.pointer == _activeDrawPointer) {
      if (_isPointerOnCanvas(event.localPosition, canvasSize)) {
        _addPointLocally(_viewportToScene(event.localPosition), event.pressure);
      } else {
        // Pointer left the canvas: end the stroke
        _finalizeDrawing();
        _activeDrawPointer = null;
      }
    } else if (_pointerPositions.length == 1 &&
        _activeDrawPointer == null &&
        !_drawingLocked &&
        _canDrawWithPointer(event) &&
        _isPointerOnCanvas(event.localPosition, canvasSize)) {
      // Pointer re-entered the canvas after leaving: start a new stroke.
      _activeDrawPointer = event.pointer;
      _startDrawingLocally(
        _viewportToScene(event.localPosition),
        event.pressure,
      );
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _pointerPositions.remove(event.pointer);
    if (_pointerPositions.isEmpty) _drawingLocked = false;

    if (_isEyedropperActive && event.pointer == _eyedropperPointer) {
      _commitEyededropperColor();
      return;
    }

    if (event.pointer == _activeDrawPointer) {
      _finalizeDrawing();
      _activeDrawPointer = null;
    }

    _finishTwoFingerGestureIfDone();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _pointerPositions.remove(event.pointer);
    if (_pointerPositions.isEmpty) _drawingLocked = false;

    if (_isEyedropperActive && event.pointer == _eyedropperPointer) {
      _cancelEyedropper();
      return;
    }

    if (event.pointer == _activeDrawPointer) {
      // For cancel, we just discard the active stroke locally
      _activeStroke.clear();
      _activeDrawPointer = null;
    }

    _finishTwoFingerGestureIfDone();
  }

  /// Ends the two-finger gesture bookkeeping once fewer than two pointers
  /// remain. The final transform is persisted to the bloc only here (once
  /// per gesture) instead of on every pointer move, which previously caused
  /// a full rebuild of the screen during pan/zoom/rotate.
  void _finishTwoFingerGestureIfDone() {
    if (_pointerPositions.length < 2) {
      if (_initialTransform != null) {
        context.read<CanvasBloc>().add(
          UpdateTransform(_transformationController.value),
        );
      }
      _initialPointerPositions = null;
      _initialTransform = null;
    } else {
      _resetTwoFingerGesture();
    }
  }

  void _startDrawingLocally(Offset point, double pressure) {
    final state = context.read<CanvasBloc>().state;
    final activeToolId = state.isEraser
        ? state.activeEraserId
        : state.activeBrushId;
    final activeTool = state.availableTools.firstWhere(
      (t) => t.id == activeToolId,
    );

    final isPressure = activeTool.isPressureSensitive;
    final effectiveSize = isPressure
        ? _effectiveSize(pressure, state)
        : state.brushSize;

    final stroke = StrokeEntity(
      points: <StrokePoint>[
        StrokePoint(offset: point, pressure: isPressure ? pressure : 1.0),
      ],
      color: state.isEraser ? Colors.white.toARGB32() : state.color.toARGB32(),
      size: state.isEraser ? effectiveSize : state.brushSize,
      opacity: state.isEraser ? 1.0 : state.opacity,
      brushType: state.isEraser ? BrushType.circle : state.brushType,
      brushId: activeToolId,
      isPressureSensitive: isPressure,
    );

    _activeStroke.begin(stroke);
    // Notify BLoC that drawing started (for status tracking)
    context.read<CanvasBloc>().add(
      StartDrawing(point: point, pressure: pressure),
    );
  }

  void _addPointLocally(Offset point, double pressure) {
    final StrokeEntity? stroke = _activeStroke.stroke;
    if (stroke == null) return;

    // Performance optimization: don't add points that are too close.
    if (stroke.points.isNotEmpty) {
      final lastPoint = stroke.points.last.offset;
      if ((point - lastPoint).distance < Constants.minPointDistance) {
        return;
      }
    }

    // Append points in place: rebuilding the points list per pointer event
    // is O(n) and makes long strokes lag behind the pointer (O(n^2) total).
    final isPressure = stroke.isPressureSensitive;
    _activeStroke.add(
      StrokePoint(offset: point, pressure: isPressure ? pressure : 1.0),
    );

    // Cap the points per stroke, seamlessly continuing with a fresh one.
    // This bounds the per-frame cost of the finished-strokes layer.
    if (stroke.points.length >= Constants.maxStrokePoints) {
      _finalizeDrawing();
      _startDrawingLocally(point, pressure);
    }
  }

  void _finalizeDrawing() {
    final StrokeEntity? stroke = _activeStroke.stroke;
    if (stroke == null) return;

    // Dispatch finalized stroke to BLoC to be added to history and persisted.
    context.read<CanvasBloc>().add(EndDrawing(stroke));

    _activeStroke.clear();
  }

  bool _canDrawWithPointer(PointerEvent event) {
    return event.kind == PointerDeviceKind.touch ||
        event.kind == PointerDeviceKind.stylus ||
        event.kind == PointerDeviceKind.mouse;
  }

  /// Whether the [stroke] covers less than a few screen pixels.
  bool _isDotStroke(StrokeEntity stroke) {
    if (stroke.points.length < 2) return true;

    double minX = stroke.points.first.offset.dx;
    double minY = stroke.points.first.offset.dy;
    double maxX = stroke.points.first.offset.dx;
    double maxY = stroke.points.first.offset.dy;
    for (final StrokePoint point in stroke.points) {
      final Offset offset = point.offset;
      if (offset.dx < minX) minX = offset.dx;
      if (offset.dy < minY) minY = offset.dy;
      if (offset.dx > maxX) maxX = offset.dx;
      if (offset.dy > maxY) maxY = offset.dy;
    }

    final double scale = _transformationController.value.getMaxScaleOnAxis();
    const double threshold = 8.0; // screen pixels
    return (maxX - minX) * scale < threshold &&
        (maxY - minY) * scale < threshold;
  }

  Offset _viewportToScene(Offset viewportPoint) {
    final Matrix4 inverse = Matrix4.inverted(_transformationController.value);
    return MatrixUtils.transformPoint(inverse, viewportPoint);
  }

  bool _isPointerOnCanvas(Offset viewportPoint, Size canvasSize) {
    final Offset scene = _viewportToScene(viewportPoint);
    return scene.dx >= 0 &&
        scene.dx <= canvasSize.width &&
        scene.dy >= 0 &&
        scene.dy <= canvasSize.height;
  }

  /// Scale at which [canvas] fits into [viewport] minus [_canvasPadding].
  double _fitScaleFor(Size viewport, Size canvas) {
    final double availableWidth = viewport.width - _canvasPadding.horizontal;
    final double availableHeight = viewport.height - _canvasPadding.vertical;
    return min(availableWidth / canvas.width, availableHeight / canvas.height);
  }

  /// Transform that centers [canvas] in [viewport] at the fit scale.
  Matrix4 _fitTransform(Size viewport, Size canvas) {
    final double scale = _fitScaleFor(viewport, canvas);
    final double dx = (viewport.width - canvas.width * scale) / 2;
    final double dy = (viewport.height - canvas.height * scale) / 2;
    return Matrix4.identity()
      ..translateByDouble(dx, dy, 0, 1)
      ..scaleByDouble(scale, scale, scale, 1);
  }

  /// Re-centers the canvas sheet in the viewport after the viewport size
  /// changed (e.g. on orientation change).
  void _recenterCanvas() {
    if (!mounted) return;

    final CanvasState state = context.read<CanvasBloc>().state;
    final Size viewportSize = MediaQuery.sizeOf(context);
    final Size canvasSize = state.contourSize ?? viewportSize;

    if (state.transform.isIdentity()) {
      // No user transform: refit the canvas sheet to the new viewport.
      _transformationController.value = _fitTransform(viewportSize, canvasSize);
      return;
    }

    // Shift the current transform so the canvas center lands on the new
    // viewport center.
    final Matrix4 matrix = _transformationController.value;
    final Offset canvasCenter = MatrixUtils.transformPoint(
      matrix,
      Offset(canvasSize.width / 2, canvasSize.height / 2),
    );
    final Offset delta = viewportSize.center(Offset.zero) - canvasCenter;
    if (delta == Offset.zero) return;

    final Matrix4 recentered = Matrix4.identity()
      ..translateByDouble(delta.dx, delta.dy, 0, 1)
      ..multiply(matrix);
    _transformationController.value = recentered;
    context.read<CanvasBloc>().add(UpdateTransform(recentered));
  }

  void _resetTwoFingerGesture() {
    _initialPointerPositions = Map<int, Offset>.from(_pointerPositions);
    _initialTransform = _transformationController.value;
  }

  void _handleTwoFingerGesture(Size canvasSize) {
    final List<Offset> initialPositions = _initialPointerPositions!.values
        .toList();
    final List<Offset> currentPositions = _pointerPositions.values.toList();

    final double initialDistance =
        (initialPositions[0] - initialPositions[1]).distance;
    final double currentDistance =
        (currentPositions[0] - currentPositions[1]).distance;
    final double scale = initialDistance > 0
        ? currentDistance / initialDistance
        : 1.0;

    final Offset initialVector = initialPositions[1] - initialPositions[0];
    final Offset currentVector = currentPositions[1] - currentPositions[0];
    final double rotation = currentVector.direction - initialVector.direction;

    final Offset initialFocal = (initialPositions[0] + initialPositions[1]) / 2;
    final Offset currentFocal = (currentPositions[0] + currentPositions[1]) / 2;

    final Matrix4 matrix = Matrix4.identity()
      ..translateByDouble(currentFocal.dx, currentFocal.dy, 0, 1)
      ..rotateZ(rotation)
      ..scaleByDouble(scale, scale, scale, 1)
      ..translateByDouble(-initialFocal.dx, -initialFocal.dy, 0, 1)
      ..multiply(_initialTransform!);

    final Matrix4 clampedMatrix = _clampTransform(matrix, canvasSize);
    // Only the local controller is updated per move event; the bloc is
    // notified once at gesture end (see [_finishTwoFingerGestureIfDone]).
    _transformationController.value = clampedMatrix;
  }

  Matrix4 _clampTransform(Matrix4 matrix, Size canvasSize) {
    final Size viewportSize = MediaQuery.sizeOf(context);
    final double fitScale = _fitScaleFor(viewportSize, canvasSize);

    final double scale = matrix.getMaxScaleOnAxis();
    final double clampedScale = scale.clamp(
      fitScale * _minScaleFactor,
      fitScale * _maxScaleFactor,
    );

    Matrix4 result = matrix;
    if (clampedScale != scale) {
      final double factor = clampedScale / scale;
      final Offset center = viewportSize.center(Offset.zero);
      result = Matrix4.identity()
        ..translateByDouble(center.dx, center.dy, 0, 1)
        ..scaleByDouble(factor, factor, factor, 1)
        ..translateByDouble(-center.dx, -center.dy, 0, 1)
        ..multiply(matrix);
    }

    final Rect bounds = _canvasBoundsOnScreen(result, canvasSize);
    double dx = 0;
    double dy = 0;
    if (bounds.right < _boundaryMargin) {
      dx = _boundaryMargin - bounds.right;
    } else if (bounds.left > viewportSize.width - _boundaryMargin) {
      dx = viewportSize.width - _boundaryMargin - bounds.left;
    }
    if (bounds.bottom < _boundaryMargin) {
      dy = _boundaryMargin - bounds.bottom;
    } else if (bounds.top > viewportSize.height - _boundaryMargin) {
      dy = viewportSize.height - _boundaryMargin - bounds.top;
    }
    if (dx != 0 || dy != 0) {
      result = Matrix4.identity()
        ..translateByDouble(dx, dy, 0, 1)
        ..multiply(result);
    }
    return result;
  }

  /// Screen-space bounding box of the canvas sheet under [matrix].
  Rect _canvasBoundsOnScreen(Matrix4 matrix, Size canvasSize) {
    final List<Offset> corners = <Offset>[
      Offset.zero,
      Offset(canvasSize.width, 0),
      Offset(0, canvasSize.height),
      Offset(canvasSize.width, canvasSize.height),
    ].map((Offset p) => MatrixUtils.transformPoint(matrix, p)).toList();

    double left = corners.first.dx;
    double right = corners.first.dx;
    double top = corners.first.dy;
    double bottom = corners.first.dy;
    for (final Offset point in corners) {
      if (point.dx < left) left = point.dx;
      if (point.dx > right) right = point.dx;
      if (point.dy < top) top = point.dy;
      if (point.dy > bottom) bottom = point.dy;
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  Future<void> _captureEyedropperImage() async {
    final RenderRepaintBoundary? boundary =
        _repaintKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) return;

    _eyedropperImage?.dispose();
    _eyedropperImage = await boundary.toImage(
      pixelRatio: View.of(context).devicePixelRatio,
    );
    _eyedropperByteData = await _eyedropperImage!.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
  }

  Color? _readColorAt(Offset viewportPoint) {
    final ui.Image? image = _eyedropperImage;
    final ByteData? byteData = _eyedropperByteData;
    if (image == null || byteData == null) return null;

    final Uint8List bytes = byteData.buffer.asUint8List();
    final int width = image.width;
    final int height = image.height;
    final RenderRepaintBoundary? boundary =
        _repaintKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    final Size boxSize =
        boundary?.size ?? Size(width.toDouble(), height.toDouble());
    final double scaleX = width / boxSize.width;
    final double scaleY = height / boxSize.height;

    final int x = (viewportPoint.dx * scaleX).clamp(0, width - 1).toInt();
    final int y = (viewportPoint.dy * scaleY).clamp(0, height - 1).toInt();
    final int index = (y * width + x) * 4;

    return Color.fromARGB(
      bytes[index + 3],
      bytes[index],
      bytes[index + 1],
      bytes[index + 2],
    );
  }

  void _initializeEyedropperAt(Offset position) {
    setState(() {
      _eyedropperPosition = position;
    });
    _refreshEyedropperColor(position);
  }

  void _startEyedropperDrag(int pointer, Offset position) {
    setState(() {
      _eyedropperPointer = pointer;
      _eyedropperPosition = position;
    });
    _refreshEyedropperColor(position);
  }

  void _updateEyedropperPosition(Offset position) {
    setState(() {
      _eyedropperPosition = position;
    });
    _refreshEyedropperColor(position);
  }

  Future<void> _refreshEyedropperColor(Offset position) async {
    if (_eyedropperCaptureFuture != null) {
      await _eyedropperCaptureFuture;
    }
    if (!mounted) return;
    final Color? color = _readColorAt(position);
    setState(() {
      _previewColor = color;
    });
  }

  Future<void> _commitEyededropperColor() async {
    if (_eyedropperCaptureFuture != null) {
      await _eyedropperCaptureFuture;
    }
    if (!mounted) return;
    final Color? color =
        _previewColor ??
        (_eyedropperPosition != null
            ? _readColorAt(_eyedropperPosition!)
            : null);
    if (color != null) {
      final bloc = context.read<CanvasBloc>();
      if (_isEyedropperForContour) {
        bloc.add(ChangeContourSettings(color: color));
      } else {
        bloc.add(ChangeColor(color));
      }
    }
    _disposeEyedropperImage();
    setState(() {
      _isEyedropperActive = false;
      _eyedropperPointer = null;
      _eyedropperPosition = null;
      _previewColor = null;
    });
  }

  Future<void> _cancelEyedropper() async {
    if (_eyedropperCaptureFuture != null) {
      await _eyedropperCaptureFuture;
    }
    if (!mounted) return;
    _disposeEyedropperImage();
    setState(() {
      _isEyedropperActive = false;
      _eyedropperPointer = null;
      _eyedropperPosition = null;
      _previewColor = null;
    });
  }

  void _disposeEyedropperImage() {
    _eyedropperImage?.dispose();
    _eyedropperImage = null;
    _eyedropperByteData = null;
  }

  void enterEyedropperMode({required bool isContour}) {
    setState(() {
      _isEyedropperActive = true;
      _isEyedropperForContour = isContour;
    });

    _eyedropperCaptureFuture = _captureEyedropperImage();
    _eyedropperCaptureFuture!.whenComplete(() {
      _eyedropperCaptureFuture = null;
    });

    final Size viewportSize = MediaQuery.sizeOf(context);
    final Offset center = Offset(
      viewportSize.width / 2,
      viewportSize.height / 2,
    );
    _initializeEyedropperAt(center);
  }

  void showExportMenu() {
    final CanvasBloc bloc = context.read<CanvasBloc>();
    if (bloc.state.contour == null) return;

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.transparent,
      pageBuilder: (dialogContext, anim1, anim2) {
        return Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 120, left: 16, right: 16),
            child: ExportMenu(
              onShare: () {
                Navigator.of(dialogContext).pop();
                _onExportSelected(bloc, ExportType.share);
              },
              onSaveToGallery: () {
                Navigator.of(dialogContext).pop();
                _onExportSelected(bloc, ExportType.gallery);
              },
            ),
          ),
        );
      },
    );
  }

  void _onExportSelected(CanvasBloc bloc, ExportType exportType) {
    bloc.add(ExportImage(exportType));
  }

  double _effectiveSize(double pressure, CanvasState state) {
    final clamped = pressure.clamp(0.0, 1.0);
    return max(Constants.minBrushSize, state.brushSize * clamped);
  }
}
