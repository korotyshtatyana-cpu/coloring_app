import '../../../domain.dart';

/// Parameters for [BuyCreditUseCase].
class BuyCreditParams {
  /// Identifier of the contour the credit will unlock.
  final String contourId;

  /// Creates parameters for a credit purchase.
  const BuyCreditParams({required this.contourId});
}

/// Starts the one-time credit purchase used to unlock a contour.
///
/// The store confirms the transaction asynchronously; the credit is spent on
/// [BuyCreditParams.contourId] before the purchase is reported as successful.
class BuyCreditUseCase implements FutureUseCase<BuyCreditParams, void> {
  final MonetizationRepository _repository;

  /// Creates a use case with the given [_repository].
  const BuyCreditUseCase({required this._repository});

  @override
  Future<void> execute([BuyCreditParams? params]) {
    if (params == null) {
      throw ArgumentError('params must not be null');
    }
    return _repository.buyCredit(contourId: params.contourId);
  }
}
