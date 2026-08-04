import '../../../domain.dart';
import '../use_case.dart';

/// Retrieves the saved language code.
class GetSettingsUseCase implements FutureUseCase<NoParams, String?> {
  final SettingsRepository _repository;

  /// Creates a use case with the given [_repository].
  const GetSettingsUseCase({required this._repository});

  @override
  Future<String?> execute([NoParams? params]) {
    return _repository.getLanguageCode();
  }
}
