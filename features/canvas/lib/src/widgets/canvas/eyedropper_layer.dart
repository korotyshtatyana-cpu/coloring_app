import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/canvas_bloc.dart';
import '../eyedropper_overlay.dart';

/// Layer for the eyedropper tool.
class EyedropperLayer extends StatelessWidget {
  /// Viewport position of the eyedropper.
  final Offset? position;

  /// Current color under the eyedropper.
  final Color? previewColor;

  /// Captured image of the canvas.
  final ui.Image? image;

  /// Creates an [EyedropperLayer].
  const EyedropperLayer({
    this.position,
    this.previewColor,
    this.image,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (position == null || previewColor == null) {
      return const SizedBox.shrink();
    }

    return BlocBuilder<CanvasBloc, CanvasState>(
      buildWhen: (CanvasState previous, CanvasState current) =>
          previous.color != current.color,
      builder: (BuildContext context, CanvasState state) {
        return EyedropperOverlay(
          position: position!,
          previewColor: previewColor!,
          selectedColor: state.color,
          image: image,
        );
      },
    );
  }
}
