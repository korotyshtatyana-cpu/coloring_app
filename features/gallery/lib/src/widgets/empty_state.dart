import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

/// Empty state shown when no contours are available.
class EmptyState extends StatelessWidget {
  /// Optional message to display.
  final String? message;

  /// Creates an [EmptyState].
  const EmptyState({this.message, super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.image_search,
            size: 64,
            color: colors.primaryText.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message ?? LocaleKeys.gallery.tr(),
            style: AppFonts.normal16.copyWith(color: colors.primaryText),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
