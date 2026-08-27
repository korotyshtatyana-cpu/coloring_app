import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

/// Button for tools in the bottom toolbar.
class ToolButton extends StatelessWidget {
  /// Icon to display.
  final IconData icon;

  /// Label text.
  final String label;

  /// Whether the tool is currently active.
  final bool isActive;

  /// Callback invoked when the button is tapped.
  final VoidCallback onTap;

  /// Creates a [ToolButton].
  const ToolButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            icon,
            color: isActive ? colors.yellow : colors.primaryText,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppFonts.normal12.copyWith(
              color: isActive ? colors.yellow : colors.primaryText,
            ),
          ),
        ],
      ),
    );
  }
}
