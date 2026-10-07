import '../../../domain.dart';

/// Parameters for [EnqueuePendingPurchaseUseCase].
class EnqueuePendingPurchaseParams {
  /// Identifier of the purchasing user.
  final String userId;

  /// Store product identifier.
  final String productId;

  /// Platform purchase token, when the store already returned one.
  final String? purchaseToken;

  /// Creates parameters for queuing a pending purchase.
  const EnqueuePendingPurchaseParams({
    required this.userId,
    required this.productId,
    this.purchaseToken,
  });
}

/// Queues a purchase that Google Play Billing has not confirmed yet.
///
/// Used when the store completed the flow but the server is unavailable: the
/// transaction is stored on the server and resolved on a later check.
class EnqueuePendingPurchaseUseCase implements FutureUseCase<EnqueuePendingPurchaseParams, void> {
  final MonetizationRepository _repository;

  /// Creates a use case with the given [_repository].
  const EnqueuePendingPurchaseUseCase({required this._repository});

  @override
  Future<void> execute([EnqueuePendingPurchaseParams? params]) {
    if (params == null) {
      throw ArgumentError('params must not be null');
    }
    return _repository.enqueuePendingPurchase(
      userId: params.userId,
      productId: params.productId,
      purchaseToken: params.purchaseToken,
    );
  }
}
