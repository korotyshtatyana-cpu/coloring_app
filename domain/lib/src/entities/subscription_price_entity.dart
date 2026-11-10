import 'package:equatable/equatable.dart';

import 'subscription_interval.dart';
import 'subscription_plan_type.dart';

/// Localized store price for one subscription base plan.
///
/// Google Play returns a formatted price per base plan, including the user's
/// local currency. The price is shown as-is so it always matches what the
/// store will charge.
class SubscriptionPriceEntity extends Equatable {
  /// Subscription plan the price belongs to.
  final SubscriptionPlanType plan;

  /// Billing interval (base plan) the price belongs to.
  final SubscriptionInterval interval;

  /// Store-formatted price, for example `249 ₽`.
  final String price;

  /// Creates a [SubscriptionPriceEntity].
  const SubscriptionPriceEntity({
    required this.plan,
    required this.interval,
    required this.price,
  });

  @override
  List<Object?> get props => <Object?>[plan, interval, price];
}
