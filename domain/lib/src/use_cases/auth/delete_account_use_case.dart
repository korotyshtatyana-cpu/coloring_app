import '../../../domain.dart';
import '../use_case.dart';

/// Triggers the account deletion process for the current user.
class DeleteAccountUseCase implements FutureUseCase<NoParams, void> {
  final AuthRepository _repository;

  /// Creates a use case with the given [_repository].
  const DeleteAccountUseCase({required this._repository});

  @override
  Future<void> execute([NoParams? params]) {
    return _repository.deleteAccount();
  }
}
