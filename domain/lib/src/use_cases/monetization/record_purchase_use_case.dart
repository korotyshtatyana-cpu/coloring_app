import '../../../domain.dart';

/// Parameters for [RecordPurchaseUseCase].
class RecordPurchaseParams {
  /// Identifier of the purchasing user.
  final String userId;

  /// Identifier of the purchased contour.
  final String contourId;

  /// Platform purchase token confirming the transaction.
  final String purchaseToken;

  /// Creates parameters for recording a purchase.
  const RecordPurchaseParams({
    required this.userId,
    required this.contourId,
    required this.purchaseToken,
  });
}

/// Records an individually purchased project.
///
/// The purchase unlocks the project permanently and is independent of the
/// current subscription status.
class RecordPurchaseUseCase implements FutureUseCase<RecordPurchaseParams, void> {
  final MonetizationRepository _repository;

  /// Creates a use case with the given [_repository].
  const RecordPurchaseUseCase({required MonetizationRepository repository})
    : _repository = repository;

  @override
  Future<void> execute([RecordPurchaseParams? params]) {
    if (params == null) {
      throw ArgumentError('params must not be null');
    }
    return _repository.recordPurchase(
      userId: params.userId,
      contourId: params.contourId,
      purchaseToken: params.purchaseToken,
    );
  }
}
