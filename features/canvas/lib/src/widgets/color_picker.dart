import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../bloc/canvas_bloc.dart';

/// Color picker dialog with color wheel and RGB sliders.
class ColorPickerDialog extends StatelessWidget {
  /// Callback invoked when the eyedropper mode is requested.
  final VoidCallback? onEyedropper;

  /// Creates a [ColorPickerDialog].
  const ColorPickerDialog({
    this.onEyedropper,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final Color currentColor = context.select(
      (CanvasBloc bloc) => bloc.state.color,
    );

    return AlertDialog(
      backgroundColor: colors.secondaryBg,
      title: Text(
        LocaleKeys.color.tr(),
        style: AppFonts.semiBold20.copyWith(color: colors.primaryText),
      ),
      content: SingleChildScrollView(
        child: ColorPicker(
          pickerColor: currentColor,
          onColorChanged: (Color color) {
            context.read<CanvasBloc>().add(ChangeColor(color));
          },
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onEyedropper?.call();
          },
          child: Text(LocaleKeys.eyedropper.tr()),
        ),
        PrimaryButton(
          text: LocaleKeys.save.tr(),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
