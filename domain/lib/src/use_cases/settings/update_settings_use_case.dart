import '../../../domain.dart';
import '../use_case.dart';

/// Saves the selected language code.
class UpdateSettingsUseCase implements FutureUseCase<String, void> {
  final SettingsRepository _repository;

  /// Creates a use case with the given [repository].
  const UpdateSettingsUseCase({required SettingsRepository repository})
      : _repository = repository;

  @override
  Future<void> execute([String? params]) {
    if (params == null) {
      throw ArgumentError('languageCode must not be null');
    }
    return _repository.saveLanguageCode(params);
  }
}
