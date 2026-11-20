import 'package:flutter/material.dart';

/// Flat marker-inspired color library for coloring books.
abstract final class MarkerColors {
  /// All library colors in `#RRGGBB` form.
  static const List<String> hexValues = <String>[
    // Reds and pinks.
    '#FF0000',
    '#FF5252',
    '#FF8A80',
    '#E91E63',
    '#F06292',
    '#F48FB1',
    '#FFCDD2',
    '#D50000',
    // Oranges and yellows.
    '#FF6D00',
    '#FF9100',
    '#FFAB40',
    '#FFC107',
    '#FFD54F',
    '#FFF59D',
    '#FFEB3B',
    '#FFE082',
    // Greens and turquoises.
    '#1B5E20',
    '#4CAF50',
    '#81C784',
    '#CDDC39',
    '#D4E157',
    '#00BCD4',
    '#009688',
    '#8BC34A',
    // Blues and cyans.
    '#0D47A1',
    '#1976D2',
    '#64B5F6',
    '#90CAF9',
    '#BBDEFB',
    '#03A9F4',
    '#4DD0E1',
    '#B2EBF2',
    // Purples.
    '#4A148C',
    '#7B1FA2',
    '#9C27B0',
    '#CE93D8',
    '#E1BEE7',
    '#673AB7',
    '#B39DDB',
    '#D1C4E9',
    // Browns and skin tones.
    '#3E2723',
    '#5D4037',
    '#8D6E63',
    '#BCAAA4',
    '#D7CCC8',
    '#FFCCBC',
    '#FFAB91',
    '#F4A460',
    // Grays and neutrals.
    '#000000',
    '#212121',
    '#424242',
    '#757575',
    '#9E9E9E',
    '#BDBDBD',
    '#E0E0E0',
    '#FFFFFF',
  ];

  /// Cached flat list with similar shades placed next to each other.
  static final List<String> sortedColors = sorted();

  /// Returns the library colors grouped by shade family and sorted from dark
  /// to light inside each family.
  ///
  /// The result is a single flat list: the dialog never shows group headers.
  static List<String> sorted() {
    final List<_Shade> shades = hexValues.map(_Shade.fromHex).toList()
      ..sort(_compareShades);
    return shades.map((_Shade shade) => shade.hex).toList();
  }
}

/// Broad shade families, ordered so neighboring families look alike.
enum _Family {
  red,
  brown,
  orange,
  yellow,
  green,
  cyan,
  blue,
  purple,
  neutral,
}

final class _Shade {
  const _Shade({
    required this.hex,
    required this.family,
    required this.lightness,
    required this.saturation,
  });

  factory _Shade.fromHex(String hex) {
    final int rgb = int.parse(hex.substring(1), radix: 16);
    final Color color = Color(0xFF000000 | rgb);
    final HSLColor hsl = HSLColor.fromColor(color);
    final HSVColor hsv = HSVColor.fromColor(color);
    return _Shade(
      hex: hex,
      family: _familyFor(hsv),
      lightness: hsl.lightness,
      saturation: hsl.saturation,
    );
  }

  final String hex;
  final _Family family;
  final double lightness;
  final double saturation;
}

_Family _familyFor(HSVColor hsv) {
  final double hue = hsv.hue;
  if (hsv.saturation < 0.05) return _Family.neutral;
  // Muted warm colors are browns and skin tones, not bright reds or oranges.
  if (hue >= 8 && hue < 45 && (hsv.saturation < 0.65 || hsv.value < 0.35)) {
    return _Family.brown;
  }
  if (hue >= 330 || hue < 15) return _Family.red;
  if (hue < 45) return _Family.orange;
  if (hue < 75) return _Family.yellow;
  if (hue < 165) return _Family.green;
  if (hue < 200) return _Family.cyan;
  if (hue < 260) return _Family.blue;
  return _Family.purple;
}

int _compareShades(_Shade a, _Shade b) {
  final int byFamily = a.family.index.compareTo(b.family.index);
  if (byFamily != 0) return byFamily;
  final int byLightness = a.lightness.compareTo(b.lightness);
  if (byLightness != 0) return byLightness;
  final int bySaturation = a.saturation.compareTo(b.saturation);
  if (bySaturation != 0) return bySaturation;
  return a.hex.compareTo(b.hex);
}
