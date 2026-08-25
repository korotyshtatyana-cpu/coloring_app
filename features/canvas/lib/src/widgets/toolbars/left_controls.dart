import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

import '../../bloc/canvas_bloc.dart';

/// Left-side control panel with brush size, opacity and view reset.
class LeftControls extends StatelessWidget {
  /// Creates [LeftControls].
  const LeftControls({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CanvasBloc>().state;
    final colors = AppColors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.metallicBlue,
        borderRadius: BorderRadius.circular(32),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppIconButton(
            size: 32,
            iconSize: 24,
            backgroundColor: colors.metallicBlue,
            icon: const Icon(Icons.brush),
            isActive: !state.isEraser,
            onPressed: () => context.read<CanvasBloc>().add(
              const SelectTool(CanvasTool.brush),
            ),
          ),
          const SizedBox(height: 8),
          AppIconButton(
            size: 32,
            iconSize: 24,
            backgroundColor: colors.metallicBlue,
            icon: const Icon(Icons.auto_fix_normal),
            isActive: state.isEraser,
            onPressed: () => context.read<CanvasBloc>().add(
              const SelectTool(CanvasTool.eraser),
            ),
          ),
          const SizedBox(height: 8),
          RotatedBox(
            quarterTurns: 3,
            child: CustomSlider(
              value: state.brushSize,
              min: Constants.minBrushSize,
              max: Constants.maxBrushSize,
              onChanged: (double value) {
                context.read<CanvasBloc>().add(ChangeBrushSize(value));
              },
            ),
          ),
          RotatedBox(
            quarterTurns: 3,
            child: CustomSlider(
              value: state.opacity,
              min: 0.0,
              max: 1.0,
              onChanged: (double value) {
                context.read<CanvasBloc>().add(ChangeOpacity(value));
              },
            ),
          ),
          const SizedBox(height: 8),
          AppIconButton(
            size: 32,
            iconSize: 24,
            backgroundColor: colors.metallicBlue,
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<CanvasBloc>().add(const ResetView()),
          ),
        ],
      ),
    );
  }
}
