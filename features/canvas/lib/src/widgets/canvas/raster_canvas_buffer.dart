import 'dart:ui' as ui;

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/canvas_bloc.dart';
import '../../painters/canvas_painter.dart';

/// Largest baked buffer edge, in physical pixels.
///
/// The buffer is `pageSize * pixelRatio`, which reaches 3917x5875 on a
/// 1536x2304 page at dpr 2.55 (~88 MB). That height exceeds the 4096 texture
/// limit, so the buffer can never be retained by the raster cache and is
/// re-uploaded every frame. Lowering the edge trades stroke sharpness under
/// zoom for a buffer the GPU can actually keep resident.
const int _kMaxBufferEdge = 2048;

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
          : RepaintBoundary(
              // Gives the buffer its own layer so it can be retained by the
              // raster cache instead of being re-uploaded on every frame.
              child: CustomPaint(
                size: widget.size,
                painter: BitmapPainter(image: _bakedImage!),
              ),
            ),
    );
  }

  Future<void> _updateBuffer(List<StrokeEntity> newStrokes) async {
    // Nothing drawn yet: there is no bitmap worth keeping. Baking a blank page
    // allocates a full-page image (tens of MB on a large contour) that has to
    // be uploaded to the GPU and kept resident, and it is all white, so the
    // page background is drawn by the stack instead. Undo back to an empty
    // page releases the buffer here.
    if (newStrokes.isEmpty) {
      _bakedStrokes = <StrokeEntity>[];
      if (_bakedImage != null && mounted) {
        setState(() {
          _bakedImage!.dispose();
          _bakedImage = null;
        });
      }
      return;
    }

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

  /// Device pixel ratio for the baked buffer, capped so the largest edge fits
  /// within [_kMaxBufferEdge].
  double _bufferPixelRatio(Size size) {
    final double dpr =
        (MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0).clamp(2.0, 3.5);
    final double longestEdge =
        size.width > size.height ? size.width : size.height;
    if (longestEdge <= 0) {
      return dpr;
    }
    final double capped = _kMaxBufferEdge / longestEdge;
    return capped < dpr ? capped : dpr;
  }

  Future<void> _fullRebake(List<StrokeEntity> strokes) async {
    final Size size = widget.size;
    final double pixelRatio = _bufferPixelRatio(size);
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
    final double pixelRatio = _bufferPixelRatio(size);
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
