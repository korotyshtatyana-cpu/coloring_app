import '../../../domain.dart';

/// Returns the plan of the given [subscription].
///
/// Returns `null` when [subscription] is `null` or no longer active, so callers
/// never treat an expired plan as valid.
class GetSubscriptionPlanTypeUseCase
    implements UseCase<SubscriptionEntity?, SubscriptionPlanType?> {
  /// Creates a use case.
  const GetSubscriptionPlanTypeUseCase();

  @override
  SubscriptionPlanType? execute([SubscriptionEntity? params]) {
    if (params == null || !params.isActiveNow()) {
      return null;
    }
    return params.planType;
  }
}
