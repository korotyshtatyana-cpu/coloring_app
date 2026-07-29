import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../bloc/canvas_bloc.dart';

/// Settings panel for contour appearance.
class ContourSettings extends StatelessWidget {
  /// Creates [ContourSettings].
  const ContourSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final state = context.watch<CanvasBloc>().state;

    return Container(
      color: colors.secondaryBg,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            LocaleKeys.contour.tr(),
            style: AppFonts.semiBold20.copyWith(color: colors.primaryText),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Text(
                LocaleKeys.contour_color.tr(),
                style: AppFonts.normal16.copyWith(color: colors.primaryText),
              ),
              const SizedBox(width: 16),
              InkWell(
                onTap: () => _showContourColorPicker(context, state.contourColor),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: state.contourColor,
                    border: Border.all(color: colors.primaryText),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomSlider(
            label: LocaleKeys.opacity.tr(),
            value: state.contourOpacity,
            min: 0.0,
            max: 1.0,
            onChanged: (double value) {
              context.read<CanvasBloc>().add(
                    ChangeContourSettings(opacity: value),
                  );
            },
          ),
          CustomSlider(
            label: LocaleKeys.brush_size.tr(),
            value: state.contourWidth,
            min: Constants.minContourWidth,
            max: Constants.maxContourWidth,
            onChanged: (double value) {
              context.read<CanvasBloc>().add(
                    ChangeContourSettings(width: value),
                  );
            },
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            text: LocaleKeys.save.tr(),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showContourColorPicker(BuildContext context, Color currentColor) {
    Color selectedColor = currentColor;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.of(context).secondaryBg,
          title: Text(
            LocaleKeys.contour_color.tr(),
            style: AppFonts.semiBold20.copyWith(
              color: AppColors.of(context).primaryText,
            ),
          ),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: selectedColor,
              onColorChanged: (Color color) {
                selectedColor = color;
              },
            ),
          ),
          actions: <Widget>[
            PrimaryButton(
              text: LocaleKeys.save.tr(),
              onPressed: () {
                context.read<CanvasBloc>().add(
                      ChangeContourSettings(color: selectedColor),
                    );
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
