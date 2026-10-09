import '../../../domain.dart';

/// Restores previously purchased subscriptions and projects.
///
/// The store reports restored transactions asynchronously through
/// [WatchPurchaseUpdatesUseCase].
class RestorePurchasesUseCase implements FutureUseCase<NoParams, void> {
  final MonetizationRepository _repository;

  /// Creates a use case with the given [_repository].
  const RestorePurchasesUseCase({required this._repository});

  @override
  Future<void> execute([NoParams? params]) {
    return _repository.restorePurchases();
  }
}
