import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

/// Overlay showing brush size or opacity preview.
class SliderOverlay extends StatelessWidget {
  /// Current value to display as text.
  final String valueText;

  /// Size of the preview circle.
  final double circleSize;

  /// Opacity of the preview circle.
  final double opacity;

  /// Color of the preview circle.
  final Color color;

  /// Creates a [SliderOverlay].
  const SliderOverlay({
    required this.valueText,
    required this.circleSize,
    required this.opacity,
    required this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return IgnorePointer(
      child: IntrinsicWidth(
        child: Material(
          color: colors.primaryBg,
          elevation: 4,
          shadowColor: colors.accentDark.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  valueText,
                  style: AppFonts.normal14.copyWith(
                    color: colors.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 160,
                  height: 120,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.secondaryBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colors.secondaryText.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Container(
                    width: circleSize,
                    height: circleSize,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: opacity),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
