import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

import '../../bloc/canvas_bloc.dart';
import '../color_picker_dialog.dart';
import '../contour_settings.dart';
import '../picker_scroll_view.dart';
import 'toolbar_container.dart';

/// Bottom toolbar with drawing tools and actions.
class BottomToolbar extends StatelessWidget {
  /// Callback invoked when the eyedropper mode is requested.
  final VoidCallback onEyedropper;

  /// Creates a [BottomToolbar].
  const BottomToolbar({required this.onEyedropper, super.key});

  @override
  Widget build(BuildContext context) {
    final bool canUndo = context.select((CanvasBloc bloc) => bloc.state.undoStack.isNotEmpty);
    final bool canRedo = context.select((CanvasBloc bloc) => bloc.state.redoStack.isNotEmpty);

    final bloc = context.read<CanvasBloc>();

    return ToolbarContainer(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          AppIconButton(
            size: 32,
            iconSize: 24,
            backgroundColor: Colors.transparent,
            icon: const Icon(Icons.color_lens),
            onPressed: () => _showColorPicker(context),
          ),
          AppIconButton(
            size: 32,
            iconSize: 24,
            backgroundColor: Colors.transparent,
            icon: const Icon(Icons.undo),
            onPressed: canUndo ? () => _onUndo(bloc) : null,
          ),
          AppIconButton(
            size: 32,
            iconSize: 24,
            backgroundColor: Colors.transparent,
            icon: const Icon(Icons.redo),
            onPressed: canRedo ? () => _onRedo(bloc) : null,
          ),
          AppIconButton(
            size: 32,
            iconSize: 24,
            backgroundColor: Colors.transparent,
            icon: const Icon(Icons.format_shapes),
            onPressed: () => _showContourSettings(context),
          ),
        ],
      ),
    );
  }

  void _onUndo(CanvasBloc bloc) {
    bloc.add(const Undo());
  }

  void _onRedo(CanvasBloc bloc) {
    bloc.add(const Redo());
  }

  void _showColorPicker(BuildContext context) {
    final bloc = context.read<CanvasBloc>();
    final colors = AppColors.of(context);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.transparent,
      pageBuilder: (dialogContext, anim1, anim2) {
        return Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
            child: Material(
              color: colors.primaryBg,
              elevation: 4,
              shadowColor: colors.accentDark.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(24),
              child: SingleChildScrollView(
                child: PickerScrollView(
                  child: BlocProvider<CanvasBloc>.value(
                    value: bloc,
                    child: ColorPickerDialog(onEyedropper: onEyedropper),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showContourSettings(BuildContext context) {
    final CanvasBloc bloc = context.read<CanvasBloc>();
    final colors = AppColors.of(context);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.transparent,
      pageBuilder: (dialogContext, anim1, anim2) {
        return Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
            child: Material(
              color: colors.primaryBg,
              elevation: 4,
              shadowColor: colors.accentDark.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(24),
              child: BlocProvider<CanvasBloc>.value(
                value: bloc,
                child: const ContourSettings(),
              ),
            ),
          ),
        );
      },
    );
  }
}
