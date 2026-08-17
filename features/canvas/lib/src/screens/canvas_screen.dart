import 'dart:ui' as ui;

import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../bloc/canvas_bloc.dart';
import '../painters/canvas_painter.dart';
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

  /// Active pointers currently on screen (viewport coordinates).
  final Map<int, Offset> _pointerPositions = <int, Offset>{};

  /// Pointer positions captured when the two-finger gesture started.
  Map<int, Offset>? _initialPointerPositions;

  /// Transform value when the two-finger gesture started.
  Matrix4? _initialTransform;

  /// Pointer that is currently drawing, if any.
  int? _activeDrawPointer;

  static const double _minScale = 0.5; // 50% (zoom out limit)
  static const double _maxScale = 5.0; // 500% (zoom in limit)
  static const double _boundaryMargin = 64.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _transformationController.dispose();
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
    return Scaffold(
      body: BlocListener<CanvasBloc, CanvasState>(
        listenWhen: (CanvasState previous, CanvasState current) =>
            previous.status != current.status ||
            previous.transform != current.transform,
        listener: (context, state) {
          _transformationController.value = state.transform;

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
                  boundaryMargin: const EdgeInsets.all(_boundaryMargin),
                  minScale: _minScale,
                  maxScale: _maxScale,
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
                      return ClipRect(
                        child: Stack(
                          fit: StackFit.expand,
                          children: <Widget>[
                            CustomPaint(
                              painter: CanvasPainter(
                                strokes: state.strokes,
                                currentStroke: state.currentStroke,
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
              child: TopToolbar(
                onExport: widget.onExport,
              ),
            ),
            const Positioned(
              left: 0,
              top: 100,
              bottom: 100,
              child: LeftControls(),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BottomToolbar(
                onEyedropper: widget.onEyedropper,
              ),
            ),
            if (_isEyedropperActive)
              Positioned.fill(
                child: Container(
                  color: Colors.black12,
                  alignment: Alignment.topCenter,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        LocaleKeys.eyedropper.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          shadows: <Shadow>[
                            Shadow(blurRadius: 4, color: Colors.black),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _onPointerDown(PointerDownEvent event) {
    _pointerPositions[event.pointer] = event.localPosition;

    if (_pointerPositions.length == 1 && _canDrawWithPointer(event)) {
      _activeDrawPointer = event.pointer;
      if (_isEyedropperActive) {
        if (_isPointerOnCanvas(event.localPosition)) {
          _pickColor(event.localPosition);
        }
        return;
      }
      if (_isPointerOnCanvas(event.localPosition)) {
        context.read<CanvasBloc>().add(
              StartDrawing(
                point: _viewportToScene(event.localPosition),
                pressure: event.pressure,
              ),
            );
      }
    } else if (_pointerPositions.length >= 2) {
      // Multiple pointers: stop drawing and switch to pan/zoom.
      if (_activeDrawPointer != null) {
        if (!_isEyedropperActive) {
          context.read<CanvasBloc>().add(const EndDrawing());
        }
        _activeDrawPointer = null;
      }
      _resetTwoFingerGesture();
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_pointerPositions.containsKey(event.pointer)) {
      return;
    }
    _pointerPositions[event.pointer] = event.localPosition;

    if (_isEyedropperActive) {
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

    if (event.pointer == _activeDrawPointer) {
      if (_isEyedropperActive) {
        _pickColor(event.localPosition);
      } else {
        context.read<CanvasBloc>().add(const EndDrawing());
      }
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

    if (event.pointer == _activeDrawPointer) {
      if (!_isEyedropperActive) {
        context.read<CanvasBloc>().add(const EndDrawing());
      }
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

  Offset _viewportToScene(Offset viewportPoint) {
    final Matrix4 inverse = Matrix4.inverted(_transformationController.value);
    return MatrixUtils.transformPoint(inverse, viewportPoint);
  }

  bool _isPointerOnCanvas(Offset viewportPoint) {
    final Size viewportSize = MediaQuery.sizeOf(context);
    final Matrix4 matrix = _transformationController.value;
    final double scale = matrix.getMaxScaleOnAxis();
    final Vector3 translation = matrix.getTranslation();

    final double left = translation.x;
    final double top = translation.y;
    final double right = left + scale * viewportSize.width;
    final double bottom = top + scale * viewportSize.height;

    return viewportPoint.dx >= left &&
        viewportPoint.dx <= right &&
        viewportPoint.dy >= top &&
        viewportPoint.dy <= bottom;
  }

  void _resetTwoFingerGesture() {
    _initialPointerPositions = Map<int, Offset>.from(_pointerPositions);
    _initialTransform = _transformationController.value;
  }

  void _handleTwoFingerGesture() {
    final List<Offset> initialPositions =
        _initialPointerPositions!.values.toList();
    final List<Offset> currentPositions = _pointerPositions.values.toList();

    final double initialDistance =
        (initialPositions[0] - initialPositions[1]).distance;
    final double currentDistance =
        (currentPositions[0] - currentPositions[1]).distance;
    final double scale = initialDistance > 0
        ? currentDistance / initialDistance
        : 1.0;

    final Offset initialFocal =
        (initialPositions[0] + initialPositions[1]) / 2;
    final Offset currentFocal =
        (currentPositions[0] + currentPositions[1]) / 2;

    final Matrix4 matrix = Matrix4.identity()
      ..translateByDouble(currentFocal.dx, currentFocal.dy, 0, 1)
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
    final double clampedScale = scale.clamp(_minScale, _maxScale);

    final Vector3 translation = matrix.getTranslation();
    final double clampedTranslationX;
    final double clampedTranslationY;

    if (clampedScale < 1.0) {
      // When the canvas is smaller than the viewport, keep it centered.
      clampedTranslationX = viewportSize.width * (1.0 - clampedScale) / 2.0;
      clampedTranslationY = viewportSize.height * (1.0 - clampedScale) / 2.0;
    } else {
      // When the canvas is larger than or equal to the viewport, allow panning
      // within the boundary margin.
      clampedTranslationX = translation.x.clamp(
        viewportSize.width -
            clampedScale * (viewportSize.width + _boundaryMargin),
        clampedScale * _boundaryMargin,
      );
      clampedTranslationY = translation.y.clamp(
        viewportSize.height -
            clampedScale * (viewportSize.height + _boundaryMargin),
        clampedScale * _boundaryMargin,
      );
    }

    return Matrix4.identity()
      ..translateByDouble(clampedTranslationX, clampedTranslationY, 0, 1)
      ..scaleByDouble(clampedScale, clampedScale, clampedScale, 1);
  }

  Future<void> _pickColor(Offset viewportPoint) async {
    final bloc = context.read<CanvasBloc>();
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(
        pixelRatio: View.of(context).devicePixelRatio,
      );
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();
      final int width = image.width;
      final int height = image.height;
      final Size boxSize = boundary.size;
      final double scaleX = width / boxSize.width;
      final double scaleY = height / boxSize.height;

      final Offset scenePoint = _viewportToScene(viewportPoint);
      final int x = (scenePoint.dx * scaleX).clamp(0, width - 1).toInt();
      final int y = (scenePoint.dy * scaleY).clamp(0, height - 1).toInt();
      final int index = (y * width + x) * 4;

      final color = Color.fromARGB(
        bytes[index + 3],
        bytes[index],
        bytes[index + 1],
        bytes[index + 2],
      );

      setState(() {
        _isEyedropperActive = false;
      });
      bloc.add(ChangeColor(color));
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace);
      setState(() {
        _isEyedropperActive = false;
      });
    }
  }

  void enterEyedropperMode() {
    setState(() {
      _isEyedropperActive = true;
    });
  }

  void showExportMenu() {
    final state = context.read<CanvasBloc>().state;
    if (state.contour == null) return;

    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return ExportMenu(
          onShare: () {
            Navigator.of(context).pop();
            context.read<CanvasBloc>().add(const ExportImage(ExportType.share));
          },
          onSaveToGallery: () {
            Navigator.of(context).pop();
            context.read<CanvasBloc>().add(const ExportImage(ExportType.gallery));
          },
        );
      },
    );
  }
}
