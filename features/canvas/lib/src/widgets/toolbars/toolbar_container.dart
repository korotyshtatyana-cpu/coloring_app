import 'package:core_ui/core_ui.dart';
import 'package:flutter/widgets.dart';

class ToolbarContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final bool isSquare;

  const ToolbarContainer({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.isSquare = false,
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
