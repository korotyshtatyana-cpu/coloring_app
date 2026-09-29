import 'dart:ui' as ui;

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/canvas_bloc.dart';
import '../../painters/canvas_painter.dart';

/// Widget that maintains a raster buffer (bitmap) of all finished strokes.
///
/// This is the key optimization for large projects: instead of drawing
/// thousands of vector paths on every frame, we flatten them into a single
/// image.
class RasterCanvasBuffer extends StatefulWidget {
  /// The project size (viewBox).
  final Size size;

  /// Creates a [RasterCanvasBuffer].
  const RasterCanvasBuffer({
    required this.size,
    super.key,
  });

  @override
  State<RasterCanvasBuffer> createState() => _RasterCanvasBufferState();
}

class _RasterCanvasBufferState extends State<RasterCanvasBuffer> {
  ui.Image? _bakedImage;
  List<StrokeEntity> _bakedStrokes = <StrokeEntity>[];

  bool _isBaking = false;
  List<StrokeEntity>? _pendingStrokes;

  @override
  void initState() {
    super.initState();
    // Start initial baking of already loaded strokes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateBuffer(context.read<CanvasBloc>().state.strokes);
      }
    });
  }

  @override
  void didUpdateWidget(RasterCanvasBuffer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.size != widget.size) {
      _bakedStrokes = <StrokeEntity>[];
      _updateBuffer(context.read<CanvasBloc>().state.strokes);
    }
  }

  @override
  void dispose() {
    _bakedImage?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CanvasBloc, CanvasState>(
      listenWhen: (CanvasState previous, CanvasState current) =>
          previous.strokes != current.strokes,
      listener: (BuildContext context, CanvasState state) {
        _updateBuffer(state.strokes);
      },
      child: _bakedImage == null
          ? const SizedBox.shrink()
          : CustomPaint(
              size: widget.size,
              painter: BitmapPainter(image: _bakedImage!),
            ),
    );
  }

  Future<void> _updateBuffer(List<StrokeEntity> newStrokes) async {
    if (_isBaking) {
      _pendingStrokes = newStrokes;
      return;
    }

    _isBaking = true;

    try {
      // 1. Full re-bake if strokes were removed (Undo) or project was loaded/cleared.
      final bool isUndoOrLoad = newStrokes.length < _bakedStrokes.length ||
          _bakedStrokes.isEmpty;

      if (isUndoOrLoad) {
        await _fullRebake(newStrokes);
      } else if (newStrokes.length > _bakedStrokes.length) {
        // 2. Incremental bake: only draw the new strokes on top.
        final List<StrokeEntity> newItems =
            newStrokes.sublist(_bakedStrokes.length);
        await _incrementalBake(newItems);
      }

      _bakedStrokes = List<StrokeEntity>.from(newStrokes);
    } finally {
      _isBaking = false;
      if (_pendingStrokes != null) {
        final List<StrokeEntity> next = _pendingStrokes!;
        _pendingStrokes = null;
        _updateBuffer(next);
      }
    }
  }

  Future<void> _fullRebake(List<StrokeEntity> strokes) async {
    final Size size = widget.size;
    final double pixelRatio =
        (MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0).clamp(2.0, 3.5);
    final int imageWidth = (size.width * pixelRatio).round();
    final int imageHeight = (size.height * pixelRatio).round();

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    canvas.scale(pixelRatio, pixelRatio);

    // Clear background and draw all strokes
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    for (final StrokeEntity stroke in strokes) {
      StrokeRenderer.drawStroke(
        canvas,
        stroke,
        visibleArea: Offset.zero & size,
      );
    }

    final ui.Picture picture = recorder.endRecording();
    final ui.Image newImage = await picture.toImage(imageWidth, imageHeight);

    if (mounted) {
      setState(() {
        _bakedImage?.dispose();
        _bakedImage = newImage;
      });
    } else {
      newImage.dispose();
    }
    picture.dispose();
  }

  Future<void> _incrementalBake(List<StrokeEntity> newStrokes) async {
    if (_bakedImage == null) {
      await _fullRebake(newStrokes);
      return;
    }

    final Size size = widget.size;
    final double pixelRatio =
        (MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0).clamp(2.0, 3.5);
    final int imageWidth = (size.width * pixelRatio).round();
    final int imageHeight = (size.height * pixelRatio).round();

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    // 1. Draw existing high-res bitmap
    canvas.drawImage(
      _bakedImage!,
      Offset.zero,
      Paint()..filterQuality = FilterQuality.medium,
    );

    // 2. Scale canvas for new strokes
    canvas.scale(pixelRatio, pixelRatio);

    // 3. Draw new strokes on top
    for (final StrokeEntity stroke in newStrokes) {
      StrokeRenderer.drawStroke(
        canvas,
        stroke,
        visibleArea: Offset.zero & size,
      );
    }

    final ui.Picture picture = recorder.endRecording();
    final ui.Image newImage = await picture.toImage(imageWidth, imageHeight);

    if (mounted) {
      setState(() {
        _bakedImage?.dispose();
        _bakedImage = newImage;
      });
    } else {
      newImage.dispose();
    }
    picture.dispose();
  }
}
