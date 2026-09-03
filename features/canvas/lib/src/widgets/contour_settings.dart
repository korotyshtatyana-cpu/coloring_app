import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

import '../bloc/canvas_bloc.dart';
import 'color_picker_dialog.dart';

/// Settings panel for contour appearance.
class ContourSettings extends StatelessWidget {
  /// Creates [ContourSettings].
  const ContourSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final Color contourColor = context.select(
      (CanvasBloc bloc) => bloc.state.contourColor,
    );
    final double contourOpacity = context.select(
      (CanvasBloc bloc) => bloc.state.contourOpacity,
    );

    final CanvasBloc bloc = context.read<CanvasBloc>();

    return IntrinsicWidth(
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Text(
                LocaleKeys.contour.tr(),
                style: AppFonts.semiBold20.copyWith(color: colors.primaryText),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  LocaleKeys.contour_color.tr(),
                  style: AppFonts.normal16.copyWith(color: colors.primaryText),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () {
                    final bloc = context.read<CanvasBloc>();
                    showGeneralDialog(
                      context: context,
                      barrierDismissible: true,
                      barrierLabel: '',
                      barrierColor: Colors.transparent,
                      pageBuilder: (dialogContext, anim1, anim2) {
                        return Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              bottom: 80,
                              left: 16,
                              right: 256,
                            ),
                            child: Material(
                              color: colors.primaryBg,
                              elevation: 4,
                              shadowColor: colors.accentDark.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(24),
                              child: SingleChildScrollView(
                                child: BlocProvider<CanvasBloc>.value(
                                  value: bloc,
                                  child: const ColorPickerDialog(
                                    isContour: true,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: ClipOval(
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: ColoredBox(color: contourColor),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              LocaleKeys.opacity.tr(),
              style: AppFonts.normal16.copyWith(color: colors.primaryText),
            ),
            SizedBox(
              width: 200,
              child: CustomSlider(
                activeColor: colors.primaryText,
                inactiveColor: colors.secondaryText.withValues(alpha: 0.2),
                gradient: LinearGradient(
                  colors: [
                    contourColor.withValues(alpha: 0),
                    contourColor.withValues(alpha: 1),
                  ],
                ),
                value: contourOpacity,
                min: 0.0,
                max: 1.0,
                onChanged: (double value) => _onOpacityChanged(bloc, value),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onOpacityChanged(CanvasBloc bloc, double value) {
    bloc.add(ChangeContourSettings(opacity: value));
  }
}
