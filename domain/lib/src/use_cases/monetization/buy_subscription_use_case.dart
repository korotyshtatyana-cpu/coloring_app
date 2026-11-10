import '../../../domain.dart';

/// Parameters for [BuySubscriptionUseCase].
class BuySubscriptionParams {
  /// Subscription plan to purchase.
  final SubscriptionPlanType plan;

  /// Billing interval to purchase.
  final SubscriptionInterval interval;

  /// Product identifier of the subscription the user already owns, if any.
  final String? currentProductId;

  /// Base plan identifier of the subscription the user already owns, if any.
  final String? currentBasePlanId;

  /// Creates parameters for a subscription purchase.
  const BuySubscriptionParams({
    required this.plan,
    required this.interval,
    this.currentProductId,
    this.currentBasePlanId,
  });
}

/// Starts the platform store purchase flow for a subscription.
///
/// The outcome is reported asynchronously through
/// [WatchPurchaseUpdatesUseCase]: a successful store flow only starts the
/// server-side verification and does not grant access by itself.
class BuySubscriptionUseCase implements FutureUseCase<BuySubscriptionParams, void> {
  final MonetizationRepository _repository;

  /// Creates a use case with the given [_repository].
  const BuySubscriptionUseCase({required this._repository});

  @override
  Future<void> execute([BuySubscriptionParams? params]) {
    if (params == null) {
      throw ArgumentError('params must not be null');
    }
    return _repository.buySubscription(
      plan: params.plan,
      interval: params.interval,
      currentProductId: params.currentProductId,
      currentBasePlanId: params.currentBasePlanId,
    );
  }
}
