/// Repository for application settings.
abstract class SettingsRepository {
  /// Returns the saved language code or null.
  Future<String?> getLanguageCode();

  /// Saves the language code.
  Future<void> saveLanguageCode(String languageCode);

  /// Returns whether the canvas onboarding slider has been shown.
  Future<bool> isCanvasOnboardingShown();

  /// Sets whether the canvas onboarding slider has been shown.
  Future<void> setCanvasOnboardingShown({bool shown = true});
}
