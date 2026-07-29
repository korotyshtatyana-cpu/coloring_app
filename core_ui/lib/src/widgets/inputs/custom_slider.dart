import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';

/// Custom slider for adjusting brush size or opacity.
class CustomSlider extends StatelessWidget {
  /// Current slider value.
  final double value;

  /// Minimum allowed value.
  final double min;

  /// Maximum allowed value.
  final double max;

  /// Callback invoked when the value changes.
  final ValueChanged<double>? onChanged;

  /// Label displayed above the slider.
  final String? label;

  /// Whether to render the slider vertically.
  final bool isVertical;

  /// Creates a [CustomSlider].
  const CustomSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.label,
    this.isVertical = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    final Widget slider = isVertical
        ? RotatedBox(
            quarterTurns: 3,
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
              activeColor: colors.secondaryBg,
              inactiveColor: colors.secondaryBg.withValues(alpha: 0.3),
            ),
          )
        : Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
            activeColor: colors.secondaryBg,
            inactiveColor: colors.secondaryBg.withValues(alpha: 0.3),
          );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (label != null)
          Text(
            label!,
            style: AppFonts.normal14.copyWith(color: colors.primaryText),
          ),
        if (isVertical) SizedBox(height: 160, child: slider) else slider,
      ],
    );
  }
}
