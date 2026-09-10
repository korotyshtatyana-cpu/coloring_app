import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

/// A vertical slider wrapper for toolbar controls.
class VerticalControlSlider extends StatelessWidget {
  /// Current slider value.
  final double value;

  /// Minimum value.
  final double min;

  /// Maximum value.
  final double max;

  /// Height of the slider.
  final double height;

  /// Callback for value changes.
  final ValueChanged<double> onChanged;

  /// Creates a [VerticalControlSlider].
  const VerticalControlSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.height,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return SizedBox(
      height: height,
      width: 32,
      child: GradientSlider(
        value: (value - min) / (max - min),
        onChanged: (double normalizedValue) {
          onChanged(min + normalizedValue * (max - min));
        },
        activeColor: colors.accentDark,
        inactiveColor: colors.secondaryText.withValues(alpha: 0.2),
        trackHeight: 8,
        thumbRadius: 10,
        isVertical: true,
      ),
    );
  }
}
