import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../utils/subscription_formatters.dart';

/// Block showing the current subscription status and remaining time.
class SubscriptionStatusBlock extends StatelessWidget {
  /// Active subscription, or `null` when the user has none.
  final SubscriptionEntity? activeSubscription;

  /// Creates a [SubscriptionStatusBlock].
  const SubscriptionStatusBlock({required this.activeSubscription, super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final SubscriptionEntity? subscription = activeSubscription;
    final bool isActive = subscription != null && subscription.isActiveNow();

    if (!isActive) {
      return _StatusCard(
        color: colors.secondaryText,
        title: LocaleKeys.subscription_status_inactive.tr(),
      );
    }

    final String planTitle = SubscriptionFormatters.planTitle(
      subscription.planType,
    );
    final String expiresAt = SubscriptionFormatters.dateTime(
      subscription.expiresAt,
    );
    final String countdown = SubscriptionFormatters.countdown(
      subscription.remainingDuration(),
    );

    return _StatusCard(
      color: colors.accentDark,
      title: LocaleKeys.subscription_status_active.tr(
        args: <String>[planTitle, expiresAt],
      ),
      trailing: countdown,
    );
  }
}

class _StatusCard extends StatelessWidget {
  final Color color;
  final String title;
  final String? trailing;

  const _StatusCard({required this.color, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.secondaryBg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.workspace_premium, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: AppFonts.normal16.copyWith(color: colors.primaryText),
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: AppFonts.semiBold20.copyWith(color: colors.accentDark),
            ),
        ],
      ),
    );
  }
}
