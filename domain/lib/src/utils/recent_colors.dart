import '../services/recent_colors_service.dart';

/// Pure helpers for normalizing and updating the recent colors list.
abstract final class RecentColors {
  /// Converts [value] to the canonical `#RRGGBB` form.
  ///
  /// Accepts values with or without a leading `#` and returns `null` for
  /// malformed input.
  static String? normalize(String value) {
    final String trimmed = value.trim().toUpperCase();
    final String hex = trimmed.startsWith('#') ? trimmed.substring(1) : trimmed;
    if (hex.length != 6 || int.tryParse(hex, radix: 16) == null) {
      return null;
    }
    return '#$hex';
  }

  /// Returns a unique, normalized list limited to [RecentColorsService.maxColors].
  ///
  /// Invalid entries are dropped and the original order is preserved.
  static List<String> sanitize(Iterable<String> colors) {
    final List<String> result = <String>[];
    for (final String color in colors) {
      final String? normalized = normalize(color);
      if (normalized == null || result.contains(normalized)) continue;
      result.add(normalized);
      if (result.length == RecentColorsService.maxColors) break;
    }
    return List<String>.unmodifiable(result);
  }

  /// Returns [colors] with [value] moved to the front.
  ///
  /// Duplicates are removed and the list is capped at
  /// [RecentColorsService.maxColors] entries.
  static List<String> remember(Iterable<String> colors, String value) {
    final String? normalized = normalize(value);
    if (normalized == null) return sanitize(colors);

    final List<String> result = <String>[normalized];
    for (final String color in sanitize(colors)) {
      if (color == normalized) continue;
      result.add(color);
      if (result.length == RecentColorsService.maxColors) break;
    }
    return List<String>.unmodifiable(result);
  }
}
