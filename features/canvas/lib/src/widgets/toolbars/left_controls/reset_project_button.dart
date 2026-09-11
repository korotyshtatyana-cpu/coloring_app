import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

import '../../../bloc/canvas_bloc.dart';

/// Button to clear all strokes and reset the project.
class ResetProjectButton extends StatelessWidget {
  /// Size of the button.
  final double size;

  /// Creates a [ResetProjectButton].
  const ResetProjectButton({
    required this.size,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      size: size,
      iconSize: 24,
      backgroundColor: Colors.transparent,
      icon: const Icon(Icons.restart_alt),
      onPressed: () => _showResetConfirmation(context),
    );
  }

  void _showResetConfirmation(BuildContext context) {
    final bloc = context.read<CanvasBloc>();
    final colors = AppColors.of(context);

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: colors.secondaryBg,
          title: Text(
            'reset_project_confirm_title'.tr(),
            style: AppFonts.semiBold20.copyWith(color: colors.accentDark),
          ),
          content: Text(
            'reset_project_confirm_message'.tr(),
            style: AppFonts.normal16.copyWith(color: colors.primaryText),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'cancel'.tr(),
                style: AppFonts.normal14.copyWith(
                  color: colors.secondaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                bloc.add(const ClearProject());
                Navigator.of(context).pop();
              },
              child: Text(
                LocaleKeys.ok.tr(),
                style: AppFonts.normal14.copyWith(
                  color: colors.accentDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
