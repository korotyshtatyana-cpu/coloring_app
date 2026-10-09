import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import 'plan_period_selector.dart';

/// Card describing a subscription plan with a period selector and CTA.
class SubscriptionPlanCard extends StatelessWidget {
  /// Plan title.
  final String title;

  /// Plan description.
  final String description;

  /// Optional badge text shown next to the title.
  final String? badge;

  /// Accent color used by the badge and the subscribe button.
  final Color accentColor;

  /// Currently selected billing interval.
  final SubscriptionInterval selectedPeriod;

  /// Called when the user selects another billing interval.
  final ValueChanged<SubscriptionInterval> onPeriodChanged;

  /// Called when the subscribe button is pressed.
  final VoidCallback onSubscribe;

  /// Whether a purchase is currently in progress.
  final bool isLoading;

  /// Creates a [SubscriptionPlanCard].
  const SubscriptionPlanCard({
    required this.title,
    required this.description,
    required this.accentColor,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.onSubscribe,
    this.badge,
    this.isLoading = false,
    super.key,
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
        border: Border.all(color: accentColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: AppFonts.semiBold20.copyWith(color: colors.primaryText),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge!,
                    style: AppFonts.normal12.copyWith(
                      color:
                          ThemeData.estimateBrightnessForColor(accentColor) ==
                              Brightness.dark
                          ? colors.white
                          : colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: AppFonts.normal14.copyWith(color: colors.secondaryText),
          ),
          const SizedBox(height: 20),
          PlanPeriodSelector(
            selected: selectedPeriod,
            onChanged: onPeriodChanged,
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            text: LocaleKeys.subscription_buy_button.tr(),
            isLoading: isLoading,
            onPressed: onSubscribe,
          ),
        ],
      ),
    );
  }
}
