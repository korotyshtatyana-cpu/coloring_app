import '../../../domain.dart';

/// Returns the products offered by the platform store.
class GetBillingProductsUseCase implements FutureUseCase<NoParams, List<BillingProductEntity>> {
  final MonetizationRepository _repository;

  /// Creates a use case with the given [_repository].
  const GetBillingProductsUseCase({required this._repository});

  @override
  Future<List<BillingProductEntity>> execute([NoParams? params]) {
    return _repository.getBillingProducts();
  }
}
