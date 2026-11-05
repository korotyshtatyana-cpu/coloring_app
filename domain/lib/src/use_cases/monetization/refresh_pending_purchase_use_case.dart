import '../../../domain.dart';

/// Re-checks a queued purchase that the store had not confirmed yet.
///
/// Invoked when the user explicitly asks to check the payment status again.
class RefreshPendingPurchaseUseCase
    implements FutureUseCase<PendingPurchaseEntity, PendingPurchaseRefreshStatus> {
  final MonetizationRepository _repository;

  /// Creates a use case with the given [_repository].
  const RefreshPendingPurchaseUseCase({required this._repository});

  @override
  Future<PendingPurchaseRefreshStatus> execute([
    PendingPurchaseEntity? params,
  ]) {
    if (params == null) {
      throw ArgumentError('params must not be null');
    }
    return _repository.refreshPendingPurchase(params);
  }
}
