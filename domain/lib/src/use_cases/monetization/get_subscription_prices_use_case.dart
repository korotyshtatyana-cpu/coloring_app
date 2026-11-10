import '../../../domain.dart';

/// Returns localized store prices for every subscription base plan.
class GetSubscriptionPricesUseCase
    implements FutureUseCase<NoParams, List<SubscriptionPriceEntity>> {
  final MonetizationRepository _repository;

  /// Creates a use case with the given [_repository].
  const GetSubscriptionPricesUseCase({required this._repository});

  @override
  Future<List<SubscriptionPriceEntity>> execute([NoParams? params]) {
    return _repository.getSubscriptionPrices();
  }
}
