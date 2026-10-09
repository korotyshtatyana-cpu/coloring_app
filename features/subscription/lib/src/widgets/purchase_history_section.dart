import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../utils/subscription_formatters.dart';

/// Section listing the user's resolved purchases.
class PurchaseHistorySection extends StatelessWidget {
  /// Resolved purchases, most recent first.
  final List<PendingPurchaseEntity> history;

  /// Creates a [PurchaseHistorySection].
  const PurchaseHistorySection({required this.history, super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          LocaleKeys.subscription_history_title.tr(),
          style: AppFonts.semiBold20.copyWith(color: colors.primaryText),
        ),
        const SizedBox(height: 12),
        if (history.isEmpty)
          Text(
            LocaleKeys.subscription_history_empty.tr(),
            style: AppFonts.normal14.copyWith(color: colors.secondaryText),
          )
        else
          ...history.map(
            (PendingPurchaseEntity purchase) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colors.secondaryBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        purchase.productId,
                        style: AppFonts.normal14.copyWith(
                          color: colors.primaryText,
                        ),
                      ),
                    ),
                    Text(
                      SubscriptionFormatters.date(
                        purchase.resolvedAt ?? purchase.createdAt,
                      ),
                      style: AppFonts.normal12.copyWith(
                        color: colors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
