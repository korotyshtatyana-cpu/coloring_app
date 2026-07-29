import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Circular icon button for toolbars and compact controls.
class AppIconButton extends StatelessWidget {
  /// The icon to display.
  final Widget icon;

  /// Callback invoked when the button is pressed.
  final VoidCallback? onPressed;

  /// Button size (width and height).
  final double size;

  /// Optional background color.
  final Color? backgroundColor;

  /// Optional tooltip.
  final String? tooltip;

  /// Creates an [AppIconButton].
  const AppIconButton({
    required this.icon,
    required this.onPressed,
    this.size = 48,
    this.backgroundColor,
    this.tooltip,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return IconButton(
      onPressed: onPressed,
      icon: icon,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor:
            backgroundColor ?? colors.secondaryBg.withValues(alpha: 0.2),
        minimumSize: Size(size, size),
        maximumSize: Size(size, size),
      ),
    );
  }
}
