import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

import '../../bloc/canvas_bloc.dart';
import '../color_picker.dart';
import '../contour_settings.dart';

/// Bottom toolbar with drawing tools and actions.
class BottomToolbar extends StatelessWidget {
  /// Callback invoked when the eyedropper mode is requested.
  final VoidCallback onEyedropper;

  /// Creates a [BottomToolbar].
  const BottomToolbar({required this.onEyedropper, super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final state = context.watch<CanvasBloc>().state;
    final bool canUndo = state.undoStack.isNotEmpty;
    final bool canRedo = state.redoStack.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: colors.metallicBlue,
        borderRadius: BorderRadius.circular(32),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          AppIconButton(
            size: 32,
            iconSize: 24,
            backgroundColor: colors.metallicBlue,
            icon: const Icon(Icons.color_lens),
            onPressed: () => _showColorPicker(context),
          ),
          AppIconButton(
            size: 32,
            iconSize: 24,
            backgroundColor: colors.metallicBlue,
            icon: const Icon(Icons.undo),
            onPressed: canUndo ? () => context.read<CanvasBloc>().add(const Undo()) : null,
          ),
          AppIconButton(
            size: 32,
            iconSize: 24,
            backgroundColor: colors.metallicBlue,
            icon: const Icon(Icons.redo),
            onPressed: canRedo ? () => context.read<CanvasBloc>().add(const Redo()) : null,
          ),
          AppIconButton(
            size: 32,
            iconSize: 24,
            backgroundColor: colors.metallicBlue,
            icon: const Icon(Icons.format_shapes),
            onPressed: () => _showContourSettings(context),
          ),
        ],
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider<CanvasBloc>.value(
        value: context.read<CanvasBloc>(),
        child: ColorPickerDialog(onEyedropper: onEyedropper),
      ),
    );
  }

  void _showContourSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => BlocProvider<CanvasBloc>.value(
        value: context.read<CanvasBloc>(),
        child: const ContourSettings(),
      ),
    );
  }
}
