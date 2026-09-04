import 'package:core/core.dart';
import 'package:flutter/material.dart';

import '../../../bloc/canvas_bloc.dart';
import 'vertical_control_slider.dart';

/// Slider to change the brush size.
class BrushSizeSlider extends StatelessWidget {
  /// Height of the slider.
  final double height;

  /// Creates a [BrushSizeSlider].
  const BrushSizeSlider({
    required this.height,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final double brushSize = context.select(
      (CanvasBloc bloc) => bloc.state.brushSize,
    );

    return VerticalControlSlider(
      value: brushSize,
      min: Constants.minBrushSize,
      max: Constants.maxBrushSize,
      height: height,
      onChanged: (double value) => context.read<CanvasBloc>().add(
            ChangeBrushSize(value),
          ),
    );
  }
}
