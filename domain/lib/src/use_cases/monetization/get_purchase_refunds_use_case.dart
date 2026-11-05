import '../../../domain.dart';

/// Returns purchase refunds the user has not seen yet.
///
/// Used by the gallery to inform the user that a purchase was refunded and is
/// therefore no longer valid.
class GetPurchaseRefundsUseCase
    implements FutureUseCase<String, List<PurchaseRefundEntity>> {
  final MonetizationRepository _repository;

  /// Creates a use case with the given [_repository].
  const GetPurchaseRefundsUseCase({required this._repository});

  @override
  Future<List<PurchaseRefundEntity>> execute([String? params]) {
    if (params == null) {
      throw ArgumentError('userId must not be null');
    }
    return _repository.getUnacknowledgedRefunds(params);
  }
}
