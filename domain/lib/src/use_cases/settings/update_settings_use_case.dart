import '../../../domain.dart';
import '../use_case.dart';

/// Saves the selected language code.
class UpdateSettingsUseCase implements FutureUseCase<String, void> {
  final SettingsRepository _repository;

  /// Creates a use case with the given [_repository].
  const UpdateSettingsUseCase({required this._repository});

  @override
  Future<void> execute([String? params]) {
    if (params == null) {
      throw ArgumentError('languageCode must not be null');
    }
    return _repository.saveLanguageCode(params);
  }
}
