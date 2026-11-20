import 'package:flutter/material.dart';

/// Formatting helpers shared by the palette and the recent colors row.
abstract final class ColorFormat {
  /// Formats [color] as an uppercase `#RRGGBB` string.
  static String toHex(Color color) {
    final String argb = color.toARGB32().toRadixString(16).padLeft(8, '0');
    return '#${argb.substring(2).toUpperCase()}';
  }

  /// Parses a `#RRGGBB` or `RRGGBB` string, returning `null` for bad input.
  static Color? tryParseHex(String value) {
    final String trimmed = value.trim();
    final String hex = trimmed.startsWith('#') ? trimmed.substring(1) : trimmed;
    if (hex.length != 6) return null;
    final int? rgb = int.tryParse(hex, radix: 16);
    if (rgb == null) return null;
    return Color(0xFF000000 | rgb);
  }
}
