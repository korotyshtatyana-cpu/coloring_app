import '../../../domain.dart';

/// Marks a refund notification as seen by the user.
class AcknowledgePurchaseRefundUseCase implements FutureUseCase<String, void> {
  final MonetizationRepository _repository;

  /// Creates a use case with the given [_repository].
  const AcknowledgePurchaseRefundUseCase({required this._repository});

  @override
  Future<void> execute([String? params]) {
    if (params == null) {
      throw ArgumentError('refundId must not be null');
    }
    return _repository.acknowledgeRefund(params);
  }
}
