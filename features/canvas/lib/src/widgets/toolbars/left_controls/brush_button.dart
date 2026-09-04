import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

import '../../../bloc/canvas_bloc.dart';

/// Button to select the brush tool.
class BrushButton extends StatelessWidget {
  /// Size of the button.
  final double size;

  /// Creates a [BrushButton].
  const BrushButton({
    required this.size,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEraser = context.select(
      (CanvasBloc bloc) => bloc.state.isEraser,
    );

    return AppIconButton(
      size: size,
      iconSize: 24,
      backgroundColor: Colors.transparent,
      icon: const Icon(Icons.brush),
      isActive: !isEraser,
      onPressed: () => context.read<CanvasBloc>().add(
            const SelectTool(CanvasTool.brush),
          ),
    );
  }
}
