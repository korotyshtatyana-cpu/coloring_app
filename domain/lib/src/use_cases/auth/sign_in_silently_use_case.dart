import '../../../domain.dart';
import '../use_case.dart';

/// Attempts to sign the user in silently using a previously authorized
/// platform account (Google Play / App Store).
class SignInSilentlyUseCase implements FutureUseCase<NoParams, UserEntity> {
  final AuthRepository _repository;

  /// Creates a use case with the given [_repository].
  const SignInSilentlyUseCase({required this._repository});

  @override
  Future<UserEntity> execute([NoParams? params]) {
    return _repository.signInSilently();
  }
}
