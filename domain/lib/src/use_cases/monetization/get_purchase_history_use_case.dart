import '../../../domain.dart';

/// Returns the user's resolved purchases, most recent first.
///
/// Only confirmed transactions are returned: pending records are handled
/// separately by [GetPendingPurchasesUseCase].
class GetPurchaseHistoryUseCase implements FutureUseCase<String, List<PendingPurchaseEntity>> {
  final MonetizationRepository _repository;

  /// Creates a use case with the given [_repository].
  const GetPurchaseHistoryUseCase({required this._repository});

  @override
  Future<List<PendingPurchaseEntity>> execute([String? params]) {
    if (params == null) {
      throw ArgumentError('userId must not be null');
    }
    return _repository.getResolvedPurchases(params);
  }
}
