import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';

/// Circular icon button for toolbars and compact controls.
class AppIconButton extends StatelessWidget {
  /// The icon to display.
  final Widget icon;

  /// Callback invoked when the button is pressed.
  final VoidCallback? onPressed;

  /// Button size (width and height).
  final double size;

  /// Optional icon size.
  final double? iconSize;

  /// Optional background color.
  final Color? backgroundColor;

  /// Optional tooltip.
  final String? tooltip;

  /// Optional label displayed below the icon.
  final String? label;

  /// Whether the button is currently active.
  final bool isActive;

  /// Creates an [AppIconButton].
  const AppIconButton({
    required this.icon,
    required this.onPressed,
    this.size = 48,
    this.iconSize,
    this.backgroundColor,
    this.tooltip,
    this.label,
    this.isActive = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final bool isDisabled = onPressed == null;

    final Color effectiveColor = isDisabled
        ? colors.primaryText.withValues(alpha: 0.3)
        : (isActive ? colors.yellow : colors.primaryText);
    final double effectiveIconSize = iconSize ?? size * 0.5;

    Widget content = IconButton(
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints.tightFor(width: size, height: size),
      icon: IconTheme(
        data: IconThemeData(
          color: effectiveColor,
          size: effectiveIconSize,
        ),
        child: icon,
      ),
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor:
            backgroundColor ?? colors.primaryBg,
        minimumSize: Size(size, size),
        maximumSize: Size(size, size),
        padding: EdgeInsets.zero,
      ),
    );

    if (label != null) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          content,
          const SizedBox(height: 4),
          Text(
            label!,
            style: AppFonts.normal12.copyWith(color: effectiveColor),
          ),
        ],
      );
    }

    return content;
  }
}
