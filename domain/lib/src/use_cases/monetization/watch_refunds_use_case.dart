import '../../../domain.dart';

/// Emits every refund reported for the user, in real time.
///
/// The app-level refund observer listens to this stream to notify the user
/// that a purchase was refunded and is no longer valid, and feature blocs use
/// it to re-resolve access immediately.
class WatchRefundsUseCase implements StreamUseCase<String, PurchaseRefundEntity> {
  final MonetizationRepository _repository;

  /// Creates a use case with the given [_repository].
  const WatchRefundsUseCase({required this._repository});

  @override
  Stream<PurchaseRefundEntity> execute([String? params]) {
    if (params == null) {
      throw ArgumentError('userId must not be null');
    }
    return _repository.watchRefunds(params);
  }
}
