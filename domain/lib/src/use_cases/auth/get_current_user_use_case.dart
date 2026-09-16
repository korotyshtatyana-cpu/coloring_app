import '../../../domain.dart';
import '../use_case.dart';

/// Returns the currently authenticated user, or `null` when there is no
/// active session.
class GetCurrentUserUseCase implements FutureUseCase<NoParams, UserEntity?> {
  final AuthRepository _repository;

  /// Creates a use case with the given [_repository].
  const GetCurrentUserUseCase({required this._repository});

  @override
  Future<UserEntity?> execute([NoParams? params]) {
    return _repository.getCurrentUser();
  }
}
