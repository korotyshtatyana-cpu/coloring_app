import '../../../domain.dart';
import '../use_case.dart';

/// Checks whether the user is authenticated.
class CheckAuthUseCase implements FutureUseCase<NoParams, bool> {
  final AuthRepository _repository;

  /// Creates a use case with the given [repository].
  const CheckAuthUseCase({required AuthRepository repository})
      : _repository = repository;

  @override
  Future<bool> execute([NoParams? params]) {
    return _repository.checkAuth();
  }
}
