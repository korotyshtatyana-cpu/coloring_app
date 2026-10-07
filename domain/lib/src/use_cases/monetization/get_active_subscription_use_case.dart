import '../../../domain.dart';

/// Returns the user's currently active subscription.
///
/// Returns `null` when the user has no active subscription. Use
/// [GetSubscriptionPlanTypeUseCase] to derive the plan from the result.
class GetActiveSubscriptionUseCase implements FutureUseCase<String, SubscriptionEntity?> {
  final MonetizationRepository _repository;

  /// Creates a use case with the given [_repository].
  const GetActiveSubscriptionUseCase({required this._repository});

  @override
  Future<SubscriptionEntity?> execute([String? params]) {
    if (params == null) {
      throw ArgumentError('userId must not be null');
    }
    return _repository.getActiveSubscription(params);
  }
}
