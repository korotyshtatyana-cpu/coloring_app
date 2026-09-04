import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

import '../../../bloc/canvas_bloc.dart';

/// Button to reset the canvas view transformation.
class ResetViewButton extends StatelessWidget {
  /// Size of the button.
  final double size;

  /// Creates a [ResetViewButton].
  const ResetViewButton({
    required this.size,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      size: size,
      iconSize: 24,
      backgroundColor: Colors.transparent,
      icon: const Icon(Icons.refresh),
      onPressed: () => context.read<CanvasBloc>().add(
            const ResetView(),
          ),
    );
  }
}
