/// Repository for application settings.
abstract class SettingsRepository {
  /// Returns the saved language code or null.
  Future<String?> getLanguageCode();

  /// Saves the language code.
  Future<void> saveLanguageCode(String languageCode);
}
