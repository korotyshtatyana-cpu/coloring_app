import '../../../domain.dart';

/// Returns the one-time credit product sold by the platform store.
class GetCreditProductUseCase
    implements FutureUseCase<NoParams, BillingProductEntity?> {
  final MonetizationRepository _repository;

  /// Creates a use case with the given [_repository].
  const GetCreditProductUseCase({required this._repository});

  @override
  Future<BillingProductEntity?> execute([NoParams? params]) {
    return _repository.getCreditProduct();
  }
}
