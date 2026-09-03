import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

import '../../bloc/canvas_bloc.dart';
import 'toolbar_container.dart';

/// Left-side control panel with brush size, opacity and view reset.
class LeftControls extends StatelessWidget {
  /// Creates [LeftControls].
  const LeftControls({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isEraser = context.select(
      (CanvasBloc bloc) => bloc.state.isEraser,
    );
    final double brushSize = context.select(
      (CanvasBloc bloc) => bloc.state.brushSize,
    );
    final double opacity = context.select(
      (CanvasBloc bloc) => bloc.state.opacity,
    );

    final AppColors colors = AppColors.of(context);
    final CanvasBloc bloc = context.read<CanvasBloc>();

    return ToolbarContainer(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppIconButton(
            size: 32,
            iconSize: 24,
            backgroundColor: Colors.transparent,
            icon: const Icon(Icons.brush),
            isActive: !isEraser,
            onPressed: () => _onSelectTool(bloc, CanvasTool.brush),
          ),
          const SizedBox(height: 8),
          AppIconButton(
            size: 32,
            iconSize: 24,
            backgroundColor: Colors.transparent,
            icon: const Icon(Icons.auto_fix_normal),
            isActive: isEraser,
            onPressed: () => _onSelectTool(bloc, CanvasTool.eraser),
          ),
          const SizedBox(height: 8),
          RotatedBox(
            quarterTurns: 3,
            child: CustomSlider(
              value: brushSize,
              activeColor: colors.accentDark,
              inactiveColor: colors.secondaryText.withValues(alpha: 0.2),
              min: Constants.minBrushSize,
              max: Constants.maxBrushSize,
              onChanged: (double value) => _onBrushSizeChanged(bloc, value),
            ),
          ),
          RotatedBox(
            quarterTurns: 3,
            child: CustomSlider(
              value: opacity,
              activeColor: colors.accentDark,
              inactiveColor: colors.secondaryText.withValues(alpha: 0.2),
              min: 0.0,
              max: 1.0,
              onChanged: (double value) => _onOpacityChanged(bloc, value),
            ),
          ),
          const SizedBox(height: 8),
          AppIconButton(
            size: 32,
            iconSize: 24,
            backgroundColor: Colors.transparent,
            icon: const Icon(Icons.refresh),
            onPressed: () => _onResetView(bloc),
          ),
        ],
      ),
    );
  }

  void _onSelectTool(CanvasBloc bloc, CanvasTool tool) {
    bloc.add(SelectTool(tool));
  }

  void _onBrushSizeChanged(CanvasBloc bloc, double value) {
    bloc.add(ChangeBrushSize(value));
  }

  void _onOpacityChanged(CanvasBloc bloc, double value) {
    bloc.add(ChangeOpacity(value));
  }

  void _onResetView(CanvasBloc bloc) {
    bloc.add(const ResetView());
  }
}
