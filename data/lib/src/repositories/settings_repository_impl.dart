import 'package:domain/domain.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Implementation of [SettingsRepository] using SharedPreferences.
class SettingsRepositoryImpl implements SettingsRepository {
  final SharedPreferences _preferences;

  static const String _languageKey = 'language_code';

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
}
