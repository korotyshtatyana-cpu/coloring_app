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

  /// Optional active color override.
  final Color? activeColor;

  /// Optional inactive color override.
  final Color? inactiveColor;

  /// Optional label color override.
  final Color? labelColor;

  /// Optional gradient for the track.
  final Gradient? gradient;

  /// Creates a [CustomSlider].
  const CustomSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.label,
    this.isVertical = false,
    this.activeColor,
    this.inactiveColor,
    this.labelColor,
    this.gradient,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final Color effectiveActiveColor = activeColor ?? colors.secondaryBg;
    final Color effectiveInactiveColor =
        inactiveColor ?? effectiveActiveColor.withValues(alpha: 0.3);
    final Color effectiveLabelColor = labelColor ?? colors.primaryText;

    Widget slider = Slider(
      value: value.clamp(min, max),
      min: min,
      max: max,
      onChanged: onChanged,
      activeColor: effectiveActiveColor,
      inactiveColor: effectiveInactiveColor,
    );

    if (gradient != null) {
      slider = SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 12,
          trackShape: _GradientSliderTrackShape(
            gradient: gradient!,
            isVertical: isVertical,
          ),
          thumbShape: const RoundSliderThumbShape(
            enabledThumbRadius: 10,
          ),
          overlayShape: const RoundSliderOverlayShape(
            overlayRadius: 20,
          ),
        ),
        child: slider,
      );
    }

    final Widget finalSlider = isVertical
        ? RotatedBox(
            quarterTurns: 3,
            child: slider,
          )
        : slider;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (label != null)
          Text(
            label!,
            style: AppFonts.normal14.copyWith(color: effectiveLabelColor),
          ),
        if (isVertical) SizedBox(height: 160, child: finalSlider) else finalSlider,
      ],
    );
  }
}

class _GradientSliderTrackShape extends SliderTrackShape with BaseSliderTrackShape {
  final Gradient gradient;
  final bool isVertical;

  _GradientSliderTrackShape({
    required this.gradient,
    required this.isVertical,
  });

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    assert(sliderTheme.disabledActiveTrackColor != null);
    assert(sliderTheme.disabledInactiveTrackColor != null);
    assert(sliderTheme.activeTrackColor != null);
    assert(sliderTheme.inactiveTrackColor != null);
    assert(sliderTheme.thumbShape != null);

    if (sliderTheme.trackHeight == null || sliderTheme.trackHeight! <= 0) {
      return;
    }

    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final activeGradientRect = Rect.fromLTRB(
      trackRect.left,
      trackRect.top,
      trackRect.right,
      trackRect.bottom,
    );

    final Paint paint = Paint()
      ..shader = gradient.createShader(activeGradientRect);

    final Radius trackRadius = Radius.circular(trackRect.height / 2);

    context.canvas.drawRRect(
      RRect.fromRectAndRadius(trackRect, trackRadius),
      paint,
    );
  }
}
