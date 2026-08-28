import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

import '../bloc/canvas_bloc.dart';
import 'color_picker.dart';

/// Settings panel for contour appearance.
class ContourSettings extends StatelessWidget {
  /// Creates [ContourSettings].
  const ContourSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final Color contourColor = context.select((CanvasBloc bloc) => bloc.state.contourColor);
    final double contourOpacity = context.select((CanvasBloc bloc) => bloc.state.contourOpacity);
    
    final CanvasBloc bloc = context.read<CanvasBloc>();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            LocaleKeys.contour.tr(),
            style: AppFonts.semiBold20.copyWith(color: Colors.black),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Text(
                LocaleKeys.contour_color.tr(),
                style: AppFonts.normal16.copyWith(color: Colors.black),
              ),
              const SizedBox(width: 16),
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
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            bottom: 80,
                            left: 16,
                            right: 16,
                          ),
                          child: Material(
                            color: Colors.white,
                            elevation: 8,
                            borderRadius: BorderRadius.circular(24),
                            child: SingleChildScrollView(
                              child: BlocProvider<CanvasBloc>.value(
                                value: bloc,
                                child: const ColorPickerDialog(isContour: true),
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
                    width: 48,
                    height: 48,
                    child: ColoredBox(
                      color: contourColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomSlider(
            label: LocaleKeys.opacity.tr(),
            labelColor: Colors.black,
            activeColor: Colors.black,
            inactiveColor: Colors.black12,
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
        ],
      ),
    );
  }

  void _onOpacityChanged(CanvasBloc bloc, double value) {
    bloc.add(ChangeContourSettings(opacity: value));
  }
}
