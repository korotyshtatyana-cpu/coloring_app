import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

/// Segmented control selecting a billing interval for a subscription plan.
class PlanPeriodSelector extends StatelessWidget {
  /// Currently selected billing interval.
  final SubscriptionInterval selected;

  /// Called when the user selects another interval.
  final ValueChanged<SubscriptionInterval> onChanged;

  /// Creates a [PlanPeriodSelector].
  const PlanPeriodSelector({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.primaryBg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: SubscriptionInterval.values.map((SubscriptionInterval interval) {
          final bool isSelected = interval == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(interval),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? colors.accentDark : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _label(interval).tr(),
                  style: AppFonts.normal14.copyWith(
                    color: isSelected ? colors.primaryBg : colors.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _label(SubscriptionInterval interval) {
    switch (interval) {
      case SubscriptionInterval.week:
        return LocaleKeys.subscription_week;
      case SubscriptionInterval.month:
        return LocaleKeys.subscription_month;
      case SubscriptionInterval.year:
        return LocaleKeys.subscription_year;
    }
  }
}
