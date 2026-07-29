import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/canvas_bloc.dart';
import '../brush_picker.dart';
import '../color_picker.dart';
import '../contour_settings.dart';

/// Bottom toolbar with drawing tools and actions.
class BottomToolbar extends StatelessWidget {
  /// Callback invoked when the eyedropper mode is requested.
  final VoidCallback onEyedropper;

  /// Creates a [BottomToolbar].
  const BottomToolbar({
    required this.onEyedropper,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final state = context.watch<CanvasBloc>().state;

    return SafeArea(
      child: Container(
        color: colors.primaryBg.withValues(alpha: 0.9),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            _ToolButton(
              icon: Icons.color_lens,
              label: LocaleKeys.color.tr(),
              isActive: false,
              onTap: () => _showColorPicker(context),
            ),
            _ToolButton(
              icon: Icons.brush,
              label: LocaleKeys.brushes.tr(),
              isActive: false,
              onTap: () => _showBrushPicker(context),
            ),
            _ToolButton(
              icon: Icons.auto_fix_normal,
              label: LocaleKeys.eraser.tr(),
              isActive: state.isEraser,
              onTap: () => context.read<CanvasBloc>().add(const ToggleEraser()),
            ),
            _ToolButton(
              icon: Icons.undo,
              label: LocaleKeys.undo.tr(),
              isActive: false,
              onTap: () => context.read<CanvasBloc>().add(const Undo()),
            ),
            _ToolButton(
              icon: Icons.redo,
              label: LocaleKeys.redo.tr(),
              isActive: false,
              onTap: () => context.read<CanvasBloc>().add(const Redo()),
            ),
            _ToolButton(
              icon: Icons.format_shapes,
              label: LocaleKeys.contour.tr(),
              isActive: false,
              onTap: () => _showContourSettings(context),
            ),
          ],
        ),
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

  void _showBrushPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => BlocProvider<CanvasBloc>.value(
        value: context.read<CanvasBloc>(),
        child: const BrushPicker(),
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

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            icon,
            color: isActive ? colors.yellow : colors.primaryText,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppFonts.normal12.copyWith(
              color: isActive ? colors.yellow : colors.primaryText,
            ),
          ),
        ],
      ),
    );
  }
}
