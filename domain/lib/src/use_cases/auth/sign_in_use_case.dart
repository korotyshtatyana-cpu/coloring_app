import '../../../domain.dart';
import '../use_case.dart';

/// Signs the user in using the platform identity provider.
class SignInUseCase implements FutureUseCase<NoParams, UserEntity> {
  final AuthRepository _repository;

  /// Creates a use case with the given [_repository].
  const SignInUseCase({required this._repository});

  @override
  Future<UserEntity> execute([NoParams? params]) {
    return _repository.signIn();
  }
}
