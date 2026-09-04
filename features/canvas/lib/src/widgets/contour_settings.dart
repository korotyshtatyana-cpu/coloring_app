import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

import '../bloc/canvas_bloc.dart';
import 'color_picker_dialog.dart';
import 'picker_scroll_view.dart';

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
                    // Distance from the right edge reserved for the contour
                    // settings panel, so the picker can sit beside it.
                    const double settingsReserve = 256;
                    // Offset applied instead when the picker must overlap the
                    // panel — a small gap so it stays slightly away from the
                    // panel edge rather than sitting flush on top.
                    const double overlapOffset = 64;
                    final double screenWidth = MediaQuery.sizeOf(context).width;
                    // The picker is ~250px wide (200px controls + padding).
                    // Reserve space for the settings panel only when it fits;
                    // otherwise open the picker on top of the panel with a
                    // small gap.
                    final bool overlapsPanel =
                        screenWidth - 16 - settingsReserve < 250;
                    showGeneralDialog(
                      context: context,
                      barrierDismissible: true,
                      barrierLabel: '',
                      barrierColor: Colors.transparent,
                      pageBuilder: (dialogContext, anim1, anim2) {
                        return Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: EdgeInsets.only(
                              bottom: overlapsPanel ? 96 : 80,
                              left: 16,
                              right: overlapsPanel
                                  ? overlapOffset
                                  : settingsReserve,
                            ),
                            child: Material(
                              color: colors.primaryBg,
                              elevation: 4,
                              shadowColor: colors.accentDark.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(24),
                              child: PickerScrollView(
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