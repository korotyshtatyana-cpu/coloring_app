import 'package:core/core.dart';
import 'package:domain/domain.dart';

/// Formatting helpers shared across subscription widgets.
abstract final class SubscriptionFormatters {
  /// Formats [date] as `dd.MM.yyyy`.
  static String date(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  /// Formats [date] as `dd.MM.yyyy HH:mm`.
  static String dateTime(DateTime date) {
    final String hour = date.hour.toString().padLeft(2, '0');
    final String minute = date.minute.toString().padLeft(2, '0');
    return '${SubscriptionFormatters.date(date)} $hour:$minute';
  }

  /// Formats a price stored in [cents] as a ruble amount.
  static String price(int cents) {
    final double rubles = cents / 100;
    final String amount = cents % 100 == 0
        ? rubles.toStringAsFixed(0)
        : rubles.toStringAsFixed(2);
    return '$amount ₽';
  }

  /// Formats [duration] as `DD:HH:MM`, clamped at zero.
  static String countdown(Duration duration) {
    final Duration safe = duration.isNegative ? Duration.zero : duration;
    final String days = safe.inDays.toString().padLeft(2, '0');
    final String hours = (safe.inHours % 24).toString().padLeft(2, '0');
    final String minutes = (safe.inMinutes % 60).toString().padLeft(2, '0');
    return '$days:$hours:$minutes';
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
}
