import 'package:domain/domain.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores recent colors in `SharedPreferences` as a list of `#RRGGBB` strings.
class RecentColorsServiceImpl implements RecentColorsService {
  /// Creates a service backed by [preferences].
  const RecentColorsServiceImpl({required this.preferences});

  /// Storage key for the serialized color list.
  static const String storageKey = 'recent_colors';

  /// Shared preferences instance used for persistence.
  final SharedPreferences preferences;

  @override
  Future<List<String>> load() async {
    return RecentColors.sanitize(
      preferences.getStringList(storageKey) ?? const <String>[],
    );
  }

  @override
  Future<List<String>> remember(String hex) async {
    final List<String> updated = RecentColors.remember(await load(), hex);
    await preferences.setStringList(storageKey, updated);
    return updated;
  }
}
