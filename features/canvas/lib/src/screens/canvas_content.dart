import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../bloc/canvas_bloc.dart';
import '../widgets/canvas/drawing_area.dart';
import '../widgets/canvas/eyedropper_layer.dart';
import '../widgets/export_menu.dart';
import '../widgets/toolbars/bottom_toolbar.dart';
import '../widgets/toolbars/left_controls.dart';
import '../widgets/toolbars/top_toolbar.dart';

/// UI implementation of the drawing canvas.
class CanvasContent extends StatefulWidget {
  /// Creates [CanvasContent].
  const CanvasContent({super.key});

  @override
  State<CanvasContent> createState() => _CanvasContentState();
}

class _CanvasContentState extends State<CanvasContent>
    with WidgetsBindingObserver {
  final TransformationController _transformationController =
      TransformationController();
  final GlobalKey _repaintKey = GlobalKey();

  bool _isEyedropperActive = false;
  int? _eyedropperPointer;
  Offset? _eyedropperPosition;
  Color? _previewColor;
  ui.Image? _eyedropperImage;
  ByteData? _eyedropperByteData;
  Future<void>? _eyedropperCaptureFuture;

  final Map<int, Offset> _pointerPositions = <int, Offset>{};
  Map<int, Offset>? _initialPointerPositions;
  Matrix4? _initialTransform;
  int? _activeDrawPointer;

  static const double _minScale = 0.5;
  static const double _maxScale = 5.0;
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
    return Scaffold(
      body: BlocListener<CanvasBloc, CanvasState>(
        listenWhen: _shouldListenToTransform,
        listener: _onTransformChanged,
        child: Stack(
          children: <Widget>[
            DrawingArea(
              repaintKey: _repaintKey,
              transformationController: _transformationController,
              onPointerDown: _onPointerDown,
              onPointerMove: _onPointerMove,
              onPointerUp: _onPointerUp,
              onPointerCancel: _onPointerCancel,
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: TopToolbar(onExport: _showExportMenu),
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
              child: BottomToolbar(onEyedropper: _enterEyedropperMode),
            ),
            EyedropperLayer(
              position: _eyedropperPosition,
              previewColor: _previewColor,
              image: _eyedropperImage,
            ),
          ],
        ),
      ),
    );
  }

  bool _shouldListenToTransform(CanvasState previous, CanvasState current) {
    return previous.status != current.status ||
        previous.transform != current.transform;
  }

  void _onTransformChanged(BuildContext context, CanvasState state) {
    _transformationController.value = state.transform;

    if (state.status == CanvasStatus.error) {
      ErrorDialog.show(
        context,
        message: state.error ?? LocaleKeys.something_went_wrong.tr(),
      );
    }
  }

  void _onPointerDown(PointerDownEvent event) {
    _pointerPositions[event.pointer] = event.localPosition;

    if (_pointerPositions.length == 1 && _canDrawWithPointer(event)) {
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
    } else if (_pointerPositions.length >= 2) {
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
    if (!_pointerPositions.containsKey(event.pointer)) return;
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
        context.read<CanvasBloc>().add(const EndDrawing());
        _activeDrawPointer = null;
      }
    } else if (_pointerPositions.length == 1 &&
        _activeDrawPointer == null &&
        _canDrawWithPointer(event) &&
        _isPointerOnCanvas(event.localPosition)) {
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
    final List<Offset> initial = _initialPointerPositions!.values.toList();
    final List<Offset> current = _pointerPositions.values.toList();

    final double initialDist = (initial[0] - initial[1]).distance;
    final double currentDist = (current[0] - current[1]).distance;
    final double scale = initialDist > 0 ? currentDist / initialDist : 1.0;

    final Offset initialFocal = (initial[0] + initial[1]) / 2;
    final Offset currentFocal = (current[0] + current[1]) / 2;

    final Matrix4 matrix = Matrix4.identity()
      ..translateByDouble(currentFocal.dx, currentFocal.dy, 0, 1)
      ..scaleByDouble(scale, scale, scale, 1)
      ..translateByDouble(-initialFocal.dx, -initialFocal.dy, 0, 1)
      ..multiply(_initialTransform!);

    final Matrix4 clamped = _clampTransform(matrix);
    _transformationController.value = clamped;
    context.read<CanvasBloc>().add(UpdateTransform(clamped));
  }

  Matrix4 _clampTransform(Matrix4 matrix) {
    final Size viewportSize = MediaQuery.sizeOf(context);
    final double scale = matrix.getMaxScaleOnAxis().clamp(_minScale, _maxScale);
    final Vector3 translation = matrix.getTranslation();

    double tx, ty;
    if (scale < 1.0) {
      tx = viewportSize.width * (1.0 - scale) / 2.0;
      ty = viewportSize.height * (1.0 - scale) / 2.0;
    } else {
      tx = translation.x.clamp(
        viewportSize.width - scale * (viewportSize.width + _boundaryMargin),
        scale * _boundaryMargin,
      );
      ty = translation.y.clamp(
        viewportSize.height - scale * (viewportSize.height + _boundaryMargin),
        scale * _boundaryMargin,
      );
    }

    return Matrix4.identity()
      ..translateByDouble(tx, ty, 0, 1)
      ..scaleByDouble(scale, scale, scale, 1);
  }

  Future<void> _captureEyedropperImage() async {
    final RenderRepaintBoundary? boundary = _repaintKey.currentContext
        ?.findRenderObject() as RenderRepaintBoundary?;
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
    final boundary =
        _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    final Size boxSize =
        boundary?.size ?? Size(width.toDouble(), height.toDouble());

    final int x =
        (viewportPoint.dx * width / boxSize.width).clamp(0, width - 1).toInt();
    final int y =
        (viewportPoint.dy * height / boxSize.height).clamp(0, height - 1).toInt();
    final int index = (y * width + x) * 4;

    return Color.fromARGB(
        bytes[index + 3], bytes[index], bytes[index + 1], bytes[index + 2]);
  }

  void _initializeEyedropperAt(Offset pos) {
    setState(() => _eyedropperPosition = pos);
    _refreshEyedropperColor(pos);
  }

  void _startEyedropperDrag(int ptr, Offset pos) {
    setState(() {
      _eyedropperPointer = ptr;
      _eyedropperPosition = pos;
    });
    _refreshEyedropperColor(pos);
  }

  void _updateEyedropperPosition(Offset pos) {
    setState(() => _eyedropperPosition = pos);
    _refreshEyedropperColor(pos);
  }

  Future<void> _refreshEyedropperColor(Offset pos) async {
    if (_eyedropperCaptureFuture != null) await _eyedropperCaptureFuture;
    if (!mounted) return;
    setState(() => _previewColor = _readColorAt(pos));
  }

  Future<void> _commitEyedropperColor() async {
    if (_eyedropperCaptureFuture != null) await _eyedropperCaptureFuture;
    if (!mounted) return;
    final Color? color = _previewColor ??
        (_eyedropperPosition != null
            ? _readColorAt(_eyedropperPosition!)
            : null);
    if (color != null) context.read<CanvasBloc>().add(ChangeColor(color));
    _disposeEyedropperImage();
    setState(() {
      _isEyedropperActive = false;
      _eyedropperPointer = null;
      _eyedropperPosition = null;
      _previewColor = null;
    });
  }

  Future<void> _cancelEyedropper() async {
    if (_eyedropperCaptureFuture != null) await _eyedropperCaptureFuture;
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

  void _enterEyedropperMode() {
    setState(() => _isEyedropperActive = true);
    _eyedropperCaptureFuture = _captureEyedropperImage();
    _eyedropperCaptureFuture!
        .whenComplete(() => _eyedropperCaptureFuture = null);
    final Size size = MediaQuery.sizeOf(context);
    _initializeEyedropperAt(Offset(size.width / 2, size.height / 2));
  }

  void _showExportMenu() {
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
            context
                .read<CanvasBloc>()
                .add(const ExportImage(ExportType.gallery));
          },
        );
      },
    );
  }
}
