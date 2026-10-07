import '../../../domain.dart';

/// Returns whether the user permanently owns the No Ads plan.
class IsNoAdsPurchasedUseCase implements FutureUseCase<String, bool> {
  final MonetizationRepository _repository;

  /// Creates a use case with the given [_repository].
  const IsNoAdsPurchasedUseCase({required this._repository});

  @override
  Future<bool> execute([String? params]) {
    if (params == null) {
      throw ArgumentError('userId must not be null');
    }
    return _repository.isNoAdsPurchased(params);
  }
}
