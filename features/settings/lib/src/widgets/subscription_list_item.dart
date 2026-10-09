import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

/// Tappable row opening the subscription screen.
class SubscriptionListItem extends StatelessWidget {
  /// Called when the row is tapped.
  final VoidCallback onTap;

  /// Creates a [SubscriptionListItem].
  const SubscriptionListItem({required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: <Widget>[
            Icon(Icons.workspace_premium, color: colors.iconPrimary, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                LocaleKeys.subscription_title.tr(),
                style: AppFonts.semiBold20.copyWith(color: colors.primaryText),
              ),
            ),
            Icon(Icons.chevron_right, color: colors.secondaryText),
          ],
        ),
      ),
    );
  }
}
