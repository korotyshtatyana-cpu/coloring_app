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

    return _StatusCard(
      color: colors.accentDark,
      title: LocaleKeys.subscription_status_active.tr(
        args: <String>[planTitle, expiresAt],
      ),
      showAutoRenewDisabled: !subscription.isAutoRenew,
    );
  }
}

class _StatusCard extends StatelessWidget {
  final Color color;
  final String title;
  final bool showAutoRenewDisabled;

  const _StatusCard({
    required this.color,
    required this.title,
    this.showAutoRenewDisabled = false,
  });

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.workspace_premium, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: AppFonts.normal16.copyWith(color: colors.primaryText),
                ),
                if (showAutoRenewDisabled) ...<Widget>[
                  const SizedBox(height: 6),
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.sync_disabled,
                        color: colors.secondaryText,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        LocaleKeys.subscription_history_auto_renewal.tr(),
                        style: AppFonts.normal12.copyWith(
                          color: colors.secondaryText,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
