import 'dart:io';
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
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';

import '../bloc/canvas_bloc.dart';
import '../painters/canvas_painter.dart';
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
      )..add(const LoadProject()),
      child: CanvasContent(
        key: _canvasKey,
        onExport: () => _canvasKey.currentState?.showExportMenu(),
        onEyedropper: () => _canvasKey.currentState?.enterEyedropperMode(),
      ),
    );
  }
}

class CanvasContent extends StatefulWidget {
  /// Callback invoked when the user taps the export button.
  final VoidCallback onExport;

  /// Callback invoked when the eyedropper mode is requested.
  final VoidCallback onEyedropper;

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

  bool _isEyedropperActive = false;

  /// Pointer currently being used by the eyedropper, if any.
  int? _eyedropperPointer;

  /// Current viewport position of the eyedropper pointer.
  Offset? _eyedropperPosition;

  /// Color currently previewed by the eyedropper.
  Color? _previewColor;

  /// Cached canvas image used while dragging the eyedropper.
  ui.Image? _eyedropperImage;

  /// Byte data of [_eyedropperImage] for fast pixel reads.
  ByteData? _eyedropperByteData;

  /// Future for the in-progress eyedropper image capture, if any.
  Future<void>? _eyedropperCaptureFuture;

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

  /// Logical size of the drawing zone, derived from the contour SVG viewBox.
  Size _canvasSize = Size.zero;

  /// Scale at which the canvas sheet fits the viewport.
  double _fitScale = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _transformationController.dispose();
    _disposeEyedropperImage();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      context.read<CanvasBloc>().add(const SaveProject());
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size viewportSize = MediaQuery.sizeOf(context);
    final ContourEntity? contour = context.select(
      (CanvasBloc bloc) => bloc.state.contour,
    );
    _canvasSize = (contour == null
            ? null
            : SvgUtils.parseViewBoxSize(contour.svgData)) ??
        viewportSize;
    _fitScale = _fitScaleFor(viewportSize, _canvasSize);

    return Scaffold(
      body: BlocListener<CanvasBloc, CanvasState>(
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
        child: BlocListener<CanvasBloc, CanvasState>(
          listenWhen: (CanvasState previous, CanvasState current) =>
              previous.status != current.status ||
              previous.transform != current.transform,
          listener: (context, state) {
            final Matrix4 transform = state.transform;
            if (transform.isIdentity()) {
              // Identity means "no user transform": fit the canvas sheet
              // into the viewport.
              final Size viewport = MediaQuery.sizeOf(context);
              final Size? svgSize = state.contour == null
                  ? null
                  : SvgUtils.parseViewBoxSize(state.contour!.svgData);
              _transformationController.value =
                  _fitTransform(viewport, svgSize ?? viewport);
            } else {
              _transformationController.value = transform;
            }

            if (state.status == CanvasStatus.error) {
              ErrorDialog.show(
                context,
                message: state.error ?? LocaleKeys.something_went_wrong.tr(),
              );
            }
          },
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: RepaintBoundary(
                  key: _repaintKey,
                  child: InteractiveViewer(
                    transformationController: _transformationController,
                    constrained: false,
                    boundaryMargin: const EdgeInsets.all(_boundaryMargin),
                    minScale: _fitScale * _minScaleFactor,
                    maxScale: _fitScale * _maxScaleFactor,
                    panEnabled: false,
                    scaleEnabled: false,
                    child: BlocBuilder<CanvasBloc, CanvasState>(
                      buildWhen: (previous, current) =>
                          previous.strokes != current.strokes ||
                          previous.currentStroke != current.currentStroke ||
                          previous.contour != current.contour ||
                          previous.contourColor != current.contourColor ||
                          previous.contourOpacity != current.contourOpacity ||
                          previous.contourWidth != current.contourWidth,
                      builder: (context, state) {
                        return SizedBox(
                          width: _canvasSize.width,
                          height: _canvasSize.height,
                          child: ClipRect(
                            child: Stack(
                              fit: StackFit.expand,
                              children: <Widget>[
                                CustomPaint(
                                  painter: CanvasPainter(
                                    strokes: state.strokes,
                                  ),
                                ),
                                if (state.contour != null)
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: Opacity(
                                        opacity: state.contourOpacity,
                                        child: SvgPicture.string(
                                          SvgUtils.applyStrokeWidth(
                                            state.contour!.svgData,
                                            state.contourWidth,
                                          ),
                                          colorFilter: ColorFilter.mode(
                                            state.contourColor,
                                            BlendMode.srcIn,
                                          ),
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: _onPointerDown,
                  onPointerMove: _onPointerMove,
                  onPointerUp: _onPointerUp,
                  onPointerCancel: _onPointerCancel,
                  child: Container(color: Colors.transparent),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: TopToolbar(onExport: widget.onExport),
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
            ],
          ),
        ),
      ),
    );
  }

  void _onPointerDown(PointerDownEvent event) {
    _pointerPositions[event.pointer] = event.localPosition;

    if (_pointerPositions.length >= 2) {
      // Multiple pointers: stop drawing and switch to pan/zoom. If the
      // first finger already started a stroke that is just a dot, discard
      // it so scaling doesn't leave stray marks.
      _drawingLocked = true;
      if (_activeDrawPointer != null) {
        if (!_isEyedropperActive) {
          final CanvasBloc bloc = context.read<CanvasBloc>();
          final StrokeEntity? stroke = bloc.state.currentStroke;
          if (stroke != null && _isDotStroke(stroke)) {
            bloc.add(const CancelDrawing());
          } else {
            bloc.add(const EndDrawing());
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
      if (_isPointerOnCanvas(event.localPosition)) {
        context.read<CanvasBloc>().add(
          StartDrawing(
            point: _viewportToScene(event.localPosition),
            pressure: event.pressure,
          ),
        );
      }
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
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
      _handleTwoFingerGesture();
    } else if (event.pointer == _activeDrawPointer) {
      if (_isPointerOnCanvas(event.localPosition)) {
        context.read<CanvasBloc>().add(
          AddPoint(
            point: _viewportToScene(event.localPosition),
            pressure: event.pressure,
          ),
        );
      } else {
        // Pointer left the canvas: end the stroke so we don't draw a
        // connecting line along the border when it comes back.
        context.read<CanvasBloc>().add(const EndDrawing());
        _activeDrawPointer = null;
      }
    } else if (_pointerPositions.length == 1 &&
        _activeDrawPointer == null &&
        !_drawingLocked &&
        _canDrawWithPointer(event) &&
        _isPointerOnCanvas(event.localPosition)) {
      // Pointer re-entered the canvas after leaving: start a new stroke.
      _activeDrawPointer = event.pointer;
      context.read<CanvasBloc>().add(
        StartDrawing(
          point: _viewportToScene(event.localPosition),
          pressure: event.pressure,
        ),
      );
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _pointerPositions.remove(event.pointer);
    if (_pointerPositions.isEmpty) _drawingLocked = false;

    if (_isEyedropperActive && event.pointer == _eyedropperPointer) {
      _commitEyedropperColor();
      return;
    }

    if (event.pointer == _activeDrawPointer) {
      context.read<CanvasBloc>().add(const EndDrawing());
      _activeDrawPointer = null;
    }

    if (_pointerPositions.length < 2) {
      _initialPointerPositions = null;
      _initialTransform = null;
    } else {
      _resetTwoFingerGesture();
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _pointerPositions.remove(event.pointer);
    if (_pointerPositions.isEmpty) _drawingLocked = false;

    if (_isEyedropperActive && event.pointer == _eyedropperPointer) {
      _cancelEyedropper();
      return;
    }

    if (event.pointer == _activeDrawPointer) {
      context.read<CanvasBloc>().add(const EndDrawing());
      _activeDrawPointer = null;
    }

    if (_pointerPositions.length < 2) {
      _initialPointerPositions = null;
      _initialTransform = null;
    } else {
      _resetTwoFingerGesture();
    }
  }

  bool _canDrawWithPointer(PointerEvent event) {
    return event.kind == PointerDeviceKind.touch ||
        event.kind == PointerDeviceKind.stylus ||
        event.kind == PointerDeviceKind.mouse;
  }

  /// Whether the [stroke] covers less than a few screen pixels — i.e. it was
  /// created by the first finger of a pinch gesture rather than deliberately.
  bool _isDotStroke(StrokeEntity stroke) {
    if (stroke.points.length < 2) return true;

    double minX = stroke.points.first.dx;
    double minY = stroke.points.first.dy;
    double maxX = stroke.points.first.dx;
    double maxY = stroke.points.first.dy;
    for (final Offset point in stroke.points) {
      if (point.dx < minX) minX = point.dx;
      if (point.dy < minY) minY = point.dy;
      if (point.dx > maxX) maxX = point.dx;
      if (point.dy > maxY) maxY = point.dy;
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

  bool _isPointerOnCanvas(Offset viewportPoint) {
    final Offset scene = _viewportToScene(viewportPoint);
    return scene.dx >= 0 &&
        scene.dx <= _canvasSize.width &&
        scene.dy >= 0 &&
        scene.dy <= _canvasSize.height;
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

  void _resetTwoFingerGesture() {
    _initialPointerPositions = Map<int, Offset>.from(_pointerPositions);
    _initialTransform = _transformationController.value;
  }

  void _handleTwoFingerGesture() {
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

    final Matrix4 clampedMatrix = _clampTransform(matrix);
    _transformationController.value = clampedMatrix;
    context.read<CanvasBloc>().add(UpdateTransform(clampedMatrix));
  }

  Matrix4 _clampTransform(Matrix4 matrix) {
    final Size viewportSize = MediaQuery.sizeOf(context);
    final double scale = matrix.getMaxScaleOnAxis();
    final double clampedScale = scale.clamp(
      _fitScale * _minScaleFactor,
      _fitScale * _maxScaleFactor,
    );

    // Adjust the scale while preserving rotation, anchored at the viewport
    // center.
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

    // Free panning: allow moving the canvas anywhere, but keep at least
    // [_boundaryMargin] of it visible on each axis so it can't get lost.
    final Rect bounds = _canvasBoundsOnScreen(result);
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
  Rect _canvasBoundsOnScreen(Matrix4 matrix) {
    final List<Offset> corners = <Offset>[
      Offset.zero,
      Offset(_canvasSize.width, 0),
      Offset(0, _canvasSize.height),
      Offset(_canvasSize.width, _canvasSize.height),
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

  Future<void> _commitEyedropperColor() async {
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
      context.read<CanvasBloc>().add(ChangeColor(color));
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

  void enterEyedropperMode() {
    setState(() {
      _isEyedropperActive = true;
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

  Future<void> _onExportSelected(CanvasBloc bloc, ExportType exportType) async {
    final String? filePath = await _captureCanvasImage();
    bloc.add(ExportImage(exportType, filePath: filePath));
  }

  /// Captures the whole canvas widget (strokes + contour with the current
  /// zoom/pan applied) into a PNG file and returns its path.
  Future<String?> _captureCanvasImage() async {
    try {
      final RenderRepaintBoundary? boundary =
          _repaintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final ui.Image image = await boundary.toImage(
        pixelRatio: View.of(context).devicePixelRatio,
      );
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      image.dispose();
      if (byteData == null) return null;

      final Directory directory = await getTemporaryDirectory();
      final File file = File(
        '${directory.path}/canvas_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(byteData.buffer.asUint8List());
      return file.path;
    } catch (e, stackTrace) {
      ErrorHandler.report(e, stackTrace);
      return null;
    }
  }
}
