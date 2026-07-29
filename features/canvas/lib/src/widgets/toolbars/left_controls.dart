import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/canvas_bloc.dart';

/// Left-side control panel with brush size, opacity and view reset.
class LeftControls extends StatelessWidget {
  /// Creates [LeftControls].
  const LeftControls({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CanvasBloc>().state;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          RotatedBox(
            quarterTurns: 3,
            child: CustomSlider(
              label: LocaleKeys.brush_size.tr(),
              value: state.brushSize,
              min: Constants.minBrushSize,
              max: Constants.maxBrushSize,
              onChanged: (double value) {
                context.read<CanvasBloc>().add(ChangeBrushSize(value));
              },
            ),
          ),
          const SizedBox(height: 24),
          RotatedBox(
            quarterTurns: 3,
            child: CustomSlider(
              label: LocaleKeys.opacity.tr(),
              value: state.opacity,
              min: 0.0,
              max: 1.0,
              onChanged: (double value) {
                context.read<CanvasBloc>().add(ChangeOpacity(value));
              },
            ),
          ),
          const SizedBox(height: 16),
          AppIconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<CanvasBloc>().add(const ResetView()),
          ),
        ],
      ),
    );
  }
}
