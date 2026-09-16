import 'package:flutter/widgets.dart';

import '../../theme/app_colors.dart';

/// A styled container for toolbar items with a soft shadow and rounded corners.
class ToolbarContainer extends StatelessWidget {
  /// The widget to display inside the container.
  final Widget child;

  /// Optional padding inside the container.
  final EdgeInsets? padding;

  /// Optional background color. Defaults to [AppColors.primaryBg].
  final Color? backgroundColor;

  /// Whether the container should be square-ish (radius 16) or pill-shaped (radius 32).
  final bool isSquare;

  /// Creates a [ToolbarContainer].
  const ToolbarContainer({
    required this.child,
    this.padding,
    this.backgroundColor,
    this.isSquare = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? colors.primaryBg,
        borderRadius: BorderRadius.circular(isSquare ? 16 : 32),
        boxShadow: [
          BoxShadow(
            color: colors.accentDark.withValues(alpha: 0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: child,
    );
  }
}
