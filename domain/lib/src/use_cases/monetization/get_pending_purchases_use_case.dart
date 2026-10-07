import '../../../domain.dart';

/// Returns the user's purchases still awaiting store confirmation.
///
/// Ordered oldest first, so the app verifies them in the order they happened.
class GetPendingPurchasesUseCase implements FutureUseCase<String, List<PendingPurchaseEntity>> {
  final MonetizationRepository _repository;

  /// Creates a use case with the given [_repository].
  const GetPendingPurchasesUseCase({required this._repository});

  @override
  Future<List<PendingPurchaseEntity>> execute([String? params]) {
    if (params == null) {
      throw ArgumentError('userId must not be null');
    }
    return _repository.getPendingPurchases(params);
  }
}
