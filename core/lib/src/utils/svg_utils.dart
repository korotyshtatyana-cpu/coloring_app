/// Utilities for manipulating SVG data strings.
abstract final class SvgUtils {
  /// Applies a [strokeWidth] to SVG elements that support strokes.
  ///
  /// Currently handles `<path>` elements. If the SVG already contains a
  /// `stroke-width` attribute, it is overwritten; otherwise it is inserted.
  static String applyStrokeWidth(String svgData, double strokeWidth) {
    return svgData.replaceAllMapped(
      RegExp(r'<path([^>]*)>', caseSensitive: false),
      (Match match) {
        final String attrs = match.group(1)!;
        if (attrs.contains('stroke-width')) {
          return '<path${attrs.replaceAllMapped(
            RegExp(r'stroke-width="[^"]*"', caseSensitive: false),
            (Match widthMatch) => 'stroke-width="$strokeWidth"',
          )}>';
        }
        return '<path$attrs stroke-width="$strokeWidth">';
      },
    );
  }
}
