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
  List<StrokeEntity> _bakedStrokes = [];
  
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
  void dispose() {
    _bakedImage?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CanvasBloc, CanvasState>(
      listenWhen: (previous, current) => previous.strokes != current.strokes,
      listener: (context, state) {
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
      // We also full rebake if the prefix doesn't match (though shouldn't happen here).
      final bool isUndoOrLoad = newStrokes.length < _bakedStrokes.length || 
                                 _bakedStrokes.isEmpty;
      
      if (isUndoOrLoad) {
        await _fullRebake(newStrokes);
      } else if (newStrokes.length > _bakedStrokes.length) {
        // 2. Incremental bake: only draw the new strokes on top.
        final newItems = newStrokes.sublist(_bakedStrokes.length);
        await _incrementalBake(newItems);
      }
      
      _bakedStrokes = List.from(newStrokes);
    } finally {
      _isBaking = false;
      if (_pendingStrokes != null) {
        final next = _pendingStrokes!;
        _pendingStrokes = null;
        _updateBuffer(next);
      }
    }
  }

  Future<void> _fullRebake(List<StrokeEntity> strokes) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final Size size = widget.size;

    // Clear background and draw all strokes
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    for (final stroke in strokes) {
      StrokeRenderer.drawStroke(canvas, stroke);
    }

    final picture = recorder.endRecording();
    final newImage = await picture.toImage(
      size.width.round(),
      size.height.round(),
    );

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

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final Size size = widget.size;

    // 1. Draw existing bitmap
    canvas.drawImage(_bakedImage!, Offset.zero, Paint());

    // 2. Draw new strokes on top
    for (final stroke in newStrokes) {
      StrokeRenderer.drawStroke(canvas, stroke);
    }

    final picture = recorder.endRecording();
    final newImage = await picture.toImage(
      size.width.round(),
      size.height.round(),
    );

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
