import 'package:core/core.dart';
import 'package:flutter/material.dart';

import '../../../bloc/canvas_bloc.dart';
import 'vertical_control_slider.dart';

/// Slider to change the brush opacity.
class OpacitySlider extends StatelessWidget {
  /// Height of the slider.
  final double height;

  /// Creates an [OpacitySlider].
  const OpacitySlider({
    required this.height,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final double opacity = context.select(
      (CanvasBloc bloc) => bloc.state.opacity,
    );

    return VerticalControlSlider(
      value: opacity,
      min: 0.0,
      max: 1.0,
      height: height,
      onChanged: (double value) => context.read<CanvasBloc>().add(
            ChangeOpacity(value),
          ),
    );
  }
}
