part of 'subscription_bloc.dart';

/// Base class for subscription events.
abstract class SubscriptionEvent extends Equatable {
  /// Creates a [SubscriptionEvent].
  const SubscriptionEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Requests loading of the active subscription and purchase history.
class LoadSubscription extends SubscriptionEvent {
  /// Creates a [LoadSubscription] event.
  const LoadSubscription();
}

/// Changes the selected billing interval of a plan.
class ChangePlanPeriod extends SubscriptionEvent {
  /// Plan whose interval is being changed.
  final SubscriptionPlanType plan;

  /// Newly selected billing interval.
  final SubscriptionInterval interval;

  /// Creates a [ChangePlanPeriod] event.
  const ChangePlanPeriod({required this.plan, required this.interval});

  @override
  List<Object?> get props => <Object?>[plan, interval];
}

/// Starts the purchase of the No Ads plan.
class PurchaseNoAds extends SubscriptionEvent {
  /// Selected billing interval.
  final SubscriptionInterval interval;

  /// Creates a [PurchaseNoAds] event.
  const PurchaseNoAds({required this.interval});

  @override
  List<Object?> get props => <Object?>[interval];
}

/// Starts the purchase of the Premium plan.
class PurchasePremium extends SubscriptionEvent {
  /// Selected billing interval.
  final SubscriptionInterval interval;

  /// Creates a [PurchasePremium] event.
  const PurchasePremium({required this.interval});

  @override
  List<Object?> get props => <Object?>[interval];
}

/// Restores previously purchased subscriptions.
class RestorePurchases extends SubscriptionEvent {
  /// Creates a [RestorePurchases] event.
  const RestorePurchases();
}

/// Internal event carrying a purchase or restore update from the billing
/// repository into the BLoC event loop.
class PurchaseUpdated extends SubscriptionEvent {
  /// Outcome reported by the billing repository.
  final PurchaseUpdateEntity update;

  /// Creates a [PurchaseUpdated] event.
  const PurchaseUpdated(this.update);

  @override
  List<Object?> get props => <Object?>[update];
}
