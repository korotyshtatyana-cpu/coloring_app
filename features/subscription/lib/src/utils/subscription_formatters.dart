import 'package:core/core.dart';
import 'package:domain/domain.dart';

/// Formatting helpers shared across subscription widgets.
abstract final class SubscriptionFormatters {
  /// Formats [date] as `dd.MM.yyyy` in the device's local timezone.
  static String date(DateTime date) {
    final DateTime local = date.toLocal();
    final String day = local.day.toString().padLeft(2, '0');
    final String month = local.month.toString().padLeft(2, '0');
    return '$day.$month.${local.year}';
  }

  /// Formats [date] as `dd.MM.yyyy HH:mm` in the device's local timezone.
  static String dateTime(DateTime date) {
    final DateTime local = date.toLocal();
    final String hour = local.hour.toString().padLeft(2, '0');
    final String minute = local.minute.toString().padLeft(2, '0');
    return '${SubscriptionFormatters.date(local)} $hour:$minute';
  }

  /// Formats a price stored in [cents] as a ruble amount.
  static String price(int cents) {
    final double rubles = cents / 100;
    final String amount = cents % 100 == 0
        ? rubles.toStringAsFixed(0)
        : rubles.toStringAsFixed(2);
    return '$amount ₽';
  }

  /// Localized title of the given subscription [planType].
  static String planTitle(SubscriptionPlanType planType) {
    switch (planType) {
      case SubscriptionPlanType.noAds:
        return LocaleKeys.subscription_no_ads_title.tr();
      case SubscriptionPlanType.premium:
        return LocaleKeys.subscription_premium_title.tr();
    }
  }

  /// Localized title of the given billing [interval].
  static String intervalTitle(SubscriptionInterval interval) {
    switch (interval) {
      case SubscriptionInterval.week:
        return LocaleKeys.subscription_week.tr();
      case SubscriptionInterval.month:
        return LocaleKeys.subscription_month.tr();
      case SubscriptionInterval.year:
        return LocaleKeys.subscription_year.tr();
    }
  }
}
