import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/canvas_bloc.dart';
import '../../painters/canvas_painter.dart';
import 'contour_layer.dart';

/// Stack of drawing and contour layers.
class CanvasStack extends StatelessWidget {
  /// Creates a [CanvasStack].
  const CanvasStack({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CanvasBloc, CanvasState>(
      buildWhen: (CanvasState previous, CanvasState current) =>
          previous.strokes != current.strokes ||
          previous.contour != current.contour ||
          previous.contourColor != current.contourColor ||
          previous.contourOpacity != current.contourOpacity ||
          previous.contourWidth != current.contourWidth,
      builder: (BuildContext context, CanvasState state) {
        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              CustomPaint(
                painter: CanvasPainter(strokes: state.strokes),
              ),
              if (state.contour != null)
                const ContourLayer(),
            ],
          ),
        );
      },
    );
  }
}
