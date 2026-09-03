import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

/// Internal chip widget for gallery filters.
class GalleryFilterChip extends StatelessWidget {
  /// Label to display on the chip.
  final String label;

  /// Whether the chip is currently active.
  final bool isActive;

  /// Callback invoked when the chip is tapped.
  final VoidCallback onTap;

  /// Creates a [GalleryFilterChip].
  const GalleryFilterChip({
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? colors.accentDark : colors.primaryBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? colors.secondaryBg : colors.accentDark),
        ),
        child: Text(
          label,
          style: AppFonts.normal14.copyWith(
            color: isActive ? Colors.white : colors.primaryText,
          ),
        ),
      ),
    );
  }
}
