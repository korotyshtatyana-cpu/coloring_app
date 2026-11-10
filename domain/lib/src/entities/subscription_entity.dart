import 'package:equatable/equatable.dart';

import 'subscription_plan_type.dart';

/// Domain entity representing a user's subscription.
class SubscriptionEntity extends Equatable {
  /// Unique subscription identifier.
  final String id;

  /// Identifier of the subscription owner.
  final String userId;

  /// Store product identifier of the plan, for example `premium`.
  final String productId;

  /// Purchased plan.
  final SubscriptionPlanType planType;

  /// Billing period (base plan) of the subscription, for example `month`.
  ///
  /// `null` for subscriptions created before the store moved to base plans.
  final String? basePlanId;

  /// Whether the subscription is marked as active on the server.
  final bool isActive;

  /// Whether Google Play will renew the subscription automatically.
  ///
  /// `false` after the user cancels auto-renew, while [expiresAt] still
  /// grants access until the paid period ends.
  final bool isAutoRenew;

  /// Moment the subscription started.
  final DateTime startedAt;

  /// Moment the subscription expires.
  final DateTime expiresAt;

  /// Platform purchase token, used to validate the subscription.
  final String? purchaseToken;

  /// Creates a [SubscriptionEntity].
  const SubscriptionEntity({
    required this.id,
    required this.userId,
    required this.productId,
    required this.planType,
    required this.isActive,
    required this.startedAt,
    required this.expiresAt,
    this.basePlanId,
    this.purchaseToken,
    this.isAutoRenew = true,
  });

  /// Whether the subscription has passed its expiry moment.
  bool isExpired([DateTime? now]) => (now ?? DateTime.now()).isAfter(expiresAt);

  /// Whether the subscription grants access at the given moment.
  ///
  /// Both the server flag and the expiry moment must be satisfied.
  bool isActiveNow([DateTime? now]) => isActive && !isExpired(now);

  /// Time left before the subscription expires.
  ///
  /// Returns [Duration.zero] when the subscription is already expired.
  Duration remainingDuration([DateTime? now]) {
    final Duration remaining = expiresAt.difference(now ?? DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    userId,
    productId,
    planType,
    basePlanId,
    isActive,
    isAutoRenew,
    startedAt,
    expiresAt,
    purchaseToken,
  ];
}
