import '../../../domain.dart';
import '../use_case.dart';

/// Checks whether the user is authenticated.
class CheckAuthUseCase implements FutureUseCase<NoParams, bool> {
  final AuthRepository _repository;

  /// Creates a use case with the given [_repository].
  const CheckAuthUseCase({required this._repository});

  @override
  Future<bool> execute([NoParams? params]) {
    return _repository.checkAuth();
  }
}
