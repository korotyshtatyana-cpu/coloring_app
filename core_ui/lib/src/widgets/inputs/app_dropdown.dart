import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';

/// A custom styled dropdown button matching the application's visual style.
class AppDropdown<T> extends StatelessWidget {
  /// The currently selected value.
  final T value;

  /// The list of items to display in the dropdown.
  final List<DropdownMenuItem<T>> items;

  /// Callback when a new item is selected.
  final ValueChanged<T?> onChanged;

  /// Optional width for the dropdown.
  final double? width;

  /// Creates an [AppDropdown].
  const AppDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    this.width,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.secondaryBg,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: colors.iconPrimary,
          ),
          dropdownColor: colors.secondaryBg,
          borderRadius: BorderRadius.circular(24),
          style: AppFonts.normal16.copyWith(color: colors.primaryText),
          isExpanded: width == null,
        ),
      ),
    );
  }
}
