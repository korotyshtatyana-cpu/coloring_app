import '../../../domain.dart';

/// Parameters for [BuyProjectUseCase].
class BuyProjectParams {
  /// Identifier of the project being purchased.
  final String contourId;

  /// Explicit store product identifier of the project, when available.
  final String? productId;

  /// Creates parameters for a project purchase.
  const BuyProjectParams({required this.contourId, this.productId});
}

/// Starts the platform store purchase flow for a single project.
///
/// The outcome is reported asynchronously through
/// [WatchPurchaseUpdatesUseCase].
class BuyProjectUseCase implements FutureUseCase<BuyProjectParams, void> {
  final MonetizationRepository _repository;

  /// Creates a use case with the given [_repository].
  const BuyProjectUseCase({required this._repository});

  @override
  Future<void> execute([BuyProjectParams? params]) {
    if (params == null) {
      throw ArgumentError('params must not be null');
    }
    return _repository.buyProject(
      contourId: params.contourId,
      productId: params.productId,
    );
  }
}
