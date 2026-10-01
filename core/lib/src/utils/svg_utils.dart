import 'dart:ui';
import 'package:http/http.dart' as http;

/// Utilities for manipulating SVG data strings.
abstract final class SvgUtils {
  /// Parses the `viewBox` attribute and returns the SVG canvas size,
  /// or null if the attribute is missing or malformed.
  static Size? parseViewBoxSize(String svgData) {
    final RegExpMatch? match = RegExp(
      'viewBox\\s*=\\s*["\']([^"\']+)["\']',
      caseSensitive: false,
    ).firstMatch(svgData);
    if (match == null) return null;

    final List<String> parts =
        match.group(1)!.trim().split(RegExp(r'[\s,]+'));
    if (parts.length != 4) return null;

    final double? width = double.tryParse(parts[2]);
    final double? height = double.tryParse(parts[3]);
    if (width == null || height == null || width <= 0 || height <= 0) {
      return null;
    }
    return Size(width, height);
  }

  /// Fetches SVG content from a URL.
  static Future<String?> fetchSvgContent(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.body;
      }
    } catch (_) {
      // Ignore errors, return null
    }
    return null;
  }
}
