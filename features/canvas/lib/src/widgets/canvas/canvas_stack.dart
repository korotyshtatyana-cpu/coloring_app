import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/canvas_bloc.dart';
import 'active_stroke.dart';
import 'contour_layer.dart';
import 'raster_canvas_buffer.dart';
import '../../painters/canvas_painter.dart';
import 'package:domain/domain.dart';

/// Stack of drawing and contour layers optimized for performance.
///
/// Separates finished strokes from the active stroke into different layers.
/// The finished strokes are flattened into a bitmap in [RasterCanvasBuffer]
/// to ensure constant-time rendering.
class CanvasStack extends StatelessWidget {
  /// Notifier for the stroke currently being drawn.
  final ActiveStroke currentStrokeNotifier;

  /// The project size (viewBox).
  final Size canvasSize;

  /// Creates a [CanvasStack].
  const CanvasStack({
    required this.currentStrokeNotifier,
    required this.canvasSize,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // Layer 1: Finished strokes (rasterized background)
          RasterCanvasBuffer(size: canvasSize),

          // Layer 2: Active stroke (redrawn via ListenableBuilder)
          _ActiveStrokeLayer(notifier: currentStrokeNotifier),

          // Layer 3: Contour (static vector on top)
          const _ContourLayerWrapper(),
        ],
      ),
    );
  }
}

class _ActiveStrokeLayer extends StatelessWidget {
  final ActiveStroke notifier;

  const _ActiveStrokeLayer({required this.notifier});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: notifier,
      builder: (context, _) {
        final StrokeEntity? currentStroke = notifier.stroke;
        if (currentStroke == null) return const SizedBox.shrink();

        return RepaintBoundary(
          child: CustomPaint(
            painter: ActiveStrokePainter(
              stroke: currentStroke,
              cachedPath: notifier.path,
              rawBounds: notifier.rawBounds,
            ),
          ),
        );
      },
    );
  }
}

class _ContourLayerWrapper extends StatelessWidget {
  const _ContourLayerWrapper();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CanvasBloc, CanvasState>(
      buildWhen: (previous, current) =>
          previous.contour != current.contour ||
          previous.contourColor != current.contourColor ||
          previous.contourOpacity != current.contourOpacity ||
          previous.isContourReady != current.isContourReady,
      builder: (context, state) {
        if (state.contour == null) return const SizedBox.shrink();
        return const Positioned.fill(
          child: RepaintBoundary(child: ContourLayer()),
        );
      },
    );
  }
}
