import 'dart:math';
import 'dart:ui' as ui;

import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
  int _pointerCount = 0;

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
                  boundaryMargin: const EdgeInsets.all(64),
                  minScale: 0.5,
                  maxScale: 5.0,
                  onInteractionUpdate: (ScaleUpdateDetails details) {
                    context.read<CanvasBloc>().add(
                          UpdateTransform(_transformationController.value),
                        );
                  },
                  child: BlocBuilder<CanvasBloc, CanvasState>(
                    buildWhen: (previous, current) =>
                        previous.strokes != current.strokes ||
                        previous.currentStroke != current.currentStroke ||
                        previous.transform != current.transform ||
                        previous.contour != current.contour ||
                        previous.contourColor != current.contourColor ||
                        previous.contourOpacity != current.contourOpacity ||
                        previous.contourWidth != current.contourWidth,
                    builder: (context, state) {
                      return Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          CustomPaint(
                            painter: CanvasPainter(
                              strokes: state.strokes,
                              currentStroke: state.currentStroke,
                              transform: state.transform,
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
                          Listener(
                            behavior: HitTestBehavior.translucent,
                            onPointerDown: _onPointerDown,
                            onPointerMove: _onPointerMove,
                            onPointerUp: _onPointerUp,
                            onPointerCancel: _onPointerCancel,
                            child: Container(color: Colors.transparent),
                          ),
                        ],
                      );
                    },
                  ),
                ),
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
    _pointerCount++;
    if (_isEyedropperActive) {
      _pickColor(event.localPosition);
      return;
    }
    if (_pointerCount > 1) return;

    context.read<CanvasBloc>().add(
          StartDrawing(point: event.localPosition, pressure: event.pressure),
        );
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_isEyedropperActive) return;
    if (_pointerCount != 1) return;

    context.read<CanvasBloc>().add(
          AddPoint(point: event.localPosition, pressure: event.pressure),
        );
  }

  void _onPointerUp(PointerUpEvent event) {
    _pointerCount = max(0, _pointerCount - 1);
    if (_isEyedropperActive) {
      _pickColor(event.localPosition);
      return;
    }
    context.read<CanvasBloc>().add(const EndDrawing());
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _pointerCount = max(0, _pointerCount - 1);
    if (_isEyedropperActive) return;
    context.read<CanvasBloc>().add(const EndDrawing());
  }

  Future<void> _pickColor(Offset localPosition) async {
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
      final width = image.width;
      final height = image.height;
      final boxSize = boundary.size;
      final scaleX = width / boxSize.width;
      final scaleY = height / boxSize.height;

      final x = (localPosition.dx * scaleX).clamp(0, width - 1).toInt();
      final y = (localPosition.dy * scaleY).clamp(0, height - 1).toInt();
      final index = (y * width + x) * 4;

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
