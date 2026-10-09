import '../../../domain.dart';

/// Emits the outcome of every purchase and restore operation.
///
/// The presentation layer listens to this stream to show purchase feedback and
/// refresh the access state.
class WatchPurchaseUpdatesUseCase implements StreamUseCase<NoParams, PurchaseUpdateEntity> {
  final MonetizationRepository _repository;

  /// Creates a use case with the given [_repository].
  const WatchPurchaseUpdatesUseCase({required this._repository});

  @override
  Stream<PurchaseUpdateEntity> execute([NoParams? params]) {
    return _repository.purchaseUpdates;
  }
}
