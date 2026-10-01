import 'package:domain/domain.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Implementation of [SettingsRepository] using SharedPreferences.
class SettingsRepositoryImpl implements SettingsRepository {
  final SharedPreferences _preferences;

  static const String _languageKey = 'language_code';
  static const String _canvasOnboardingKey = 'canvas_onboarding_shown';

  /// Creates a repository with the given [_preferences].
  SettingsRepositoryImpl({required this._preferences});

  @override
  Future<String?> getLanguageCode() async {
    return _preferences.getString(_languageKey);
  }

  @override
  Future<void> saveLanguageCode(String languageCode) async {
    await _preferences.setString(_languageKey, languageCode);
  }

  @override
  Future<bool> isCanvasOnboardingShown() async {
    return _preferences.getBool(_canvasOnboardingKey) ?? false;
  }

  @override
  Future<void> setCanvasOnboardingShown({bool shown = true}) async {
    await _preferences.setBool(_canvasOnboardingKey, shown);
  }
}
