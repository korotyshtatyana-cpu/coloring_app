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
    final bool isEraser = context.select((CanvasBloc bloc) => bloc.state.isEraser);
    final double brushSize = context.select((CanvasBloc bloc) => bloc.state.brushSize);
    final double opacity = context.select((CanvasBloc bloc) => bloc.state.opacity);
    
    final AppColors colors = AppColors.of(context);
    final CanvasBloc bloc = context.read<CanvasBloc>();
    const spacer8 = SizedBox(height: 8);

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
            isActive: !isEraser,
            onPressed: () => _onSelectTool(bloc, CanvasTool.brush),
          ),
          spacer8,
          AppIconButton(
            size: 32,
            iconSize: 24,
            backgroundColor: colors.metallicBlue,
            icon: const Icon(Icons.auto_fix_normal),
            isActive: isEraser,
            onPressed: () => _onSelectTool(bloc, CanvasTool.eraser),
          ),
          spacer8,
          RotatedBox(
            quarterTurns: 3,
            child: CustomSlider(
              value: brushSize,
              min: Constants.minBrushSize,
              max: Constants.maxBrushSize,
              onChanged: (double value) => _onBrushSizeChanged(bloc, value),
            ),
          ),
          RotatedBox(
            quarterTurns: 3,
            child: CustomSlider(
              value: opacity,
              min: 0.0,
              max: 1.0,
              onChanged: (double value) => _onOpacityChanged(bloc, value),
            ),
          ),
          spacer8,
          AppIconButton(
            size: 32,
            iconSize: 24,
            backgroundColor: colors.metallicBlue,
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
