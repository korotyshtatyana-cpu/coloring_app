import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

/// A custom slider with a gradient track or a dual-color solid track.
class GradientSlider extends StatelessWidget {
  /// Current value (0.0 to 1.0).
  final double value;

  /// Callback for value changes.
  final ValueChanged<double> onChanged;

  /// Optional gradient for the track. If provided, [activeColor] and
  /// [inactiveColor] are ignored.
  final Gradient? gradient;

  /// Color for the active (filled) part of the track.
  final Color? activeColor;

  /// Color for the inactive (unfilled) part of the track.
  final Color? inactiveColor;

  /// Height of the container (or width if vertical).
  final double height;

  /// Thickness of the visible track.
  final double trackHeight;

  /// Radius of the thumb.
  final double thumbRadius;

  /// Color of the thumb. If null, uses [AppColors.accentDark].
  final Color? thumbColor;

  /// Whether to render the slider vertically.
  final bool isVertical;

  /// Creates a [GradientSlider].
  const GradientSlider({
    required this.value,
    required this.onChanged,
    this.gradient,
    this.activeColor,
    this.inactiveColor,
    this.height = 40,
    this.trackHeight = 8,
    this.thumbRadius = 10,
    this.thumbColor,
    this.isVertical = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final Color effectiveThumbColor = thumbColor ?? colors.accentDark;
    final Color effectiveActiveColor = activeColor ?? colors.accentDark;
    final Color effectiveInactiveColor =
        inactiveColor ?? colors.secondaryText.withValues(alpha: 0.2);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double totalLength = isVertical ? constraints.maxHeight : constraints.maxWidth;
        final double crossAxisLength = isVertical ? constraints.maxWidth : constraints.maxHeight;

        final double sidePadding = thumbRadius + 4;
        final double trackLength = totalLength - (sidePadding * 2);

        return GestureDetector(
          onPanUpdate: (DragUpdateDetails d) {
            final double localPos = isVertical ? d.localPosition.dy : d.localPosition.dx;
            final double relativePos = localPos - sidePadding;
            double newValue;
            if (isVertical) {
              newValue = 1.0 - (relativePos / trackLength);
            } else {
              newValue = relativePos / trackLength;
            }
            onChanged(newValue.clamp(0.0, 1.0));
          },
          onTapDown: (TapDownDetails d) {
            final double localPos = isVertical ? d.localPosition.dy : d.localPosition.dx;
            final double relativePos = localPos - sidePadding;
            double newValue;
            if (isVertical) {
              newValue = 1.0 - (relativePos / trackLength);
            } else {
              newValue = relativePos / trackLength;
            }
            onChanged(newValue.clamp(0.0, 1.0));
          },
          child: Container(
            width: isVertical ? crossAxisLength : totalLength,
            height: isVertical ? totalLength : crossAxisLength,
            color: Colors.transparent,
            child: Stack(
              alignment: isVertical ? Alignment.topCenter : Alignment.centerLeft,
              children: <Widget>[
                // Track Background (or full gradient)
                Positioned(
                  left: isVertical ? (crossAxisLength - trackHeight) / 2 : sidePadding,
                  right: isVertical ? (crossAxisLength - trackHeight) / 2 : sidePadding,
                  top: isVertical ? sidePadding : (crossAxisLength - trackHeight) / 2,
                  bottom: isVertical ? sidePadding : (crossAxisLength - trackHeight) / 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: gradient == null ? effectiveInactiveColor : null,
                      gradient: gradient != null
                          ? (isVertical
                              ? LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: gradient!.colors,
                                  stops: gradient!.stops,
                                )
                              : gradient)
                          : null,
                      borderRadius: BorderRadius.circular(trackHeight / 2),
                    ),
                  ),
                ),
                // Active Track (Solid Mode)
                if (gradient == null)
                  Positioned(
                    left: isVertical
                        ? (crossAxisLength - trackHeight) / 2
                        : sidePadding,
                    right: isVertical
                        ? (crossAxisLength - trackHeight) / 2
                        : sidePadding + ((1.0 - value) * trackLength),
                    top: isVertical
                        ? sidePadding + ((1.0 - value) * trackLength)
                        : (crossAxisLength - trackHeight) / 2,
                    bottom: isVertical
                        ? sidePadding
                        : (crossAxisLength - trackHeight) / 2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: effectiveActiveColor,
                        borderRadius: BorderRadius.circular(trackHeight / 2),
                      ),
                    ),
                  ),
                // Thumb
                Positioned(
                  left: isVertical
                      ? (crossAxisLength / 2) - thumbRadius
                      : sidePadding + (value * trackLength) - thumbRadius,
                  top: isVertical
                      ? sidePadding + ((1.0 - value) * trackLength) - thumbRadius
                      : (crossAxisLength / 2) - thumbRadius,
                  child: Container(
                    width: thumbRadius * 2,
                    height: thumbRadius * 2,
                    decoration: BoxDecoration(
                      color: effectiveThumbColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
