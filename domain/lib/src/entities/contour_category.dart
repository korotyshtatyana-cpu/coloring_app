/// Enum representing the available contour categories.
enum ContourCategory {
  /// All categories (UI-only, not stored on contours).
  all,

  /// Animals category.
  animals,

  /// Nature category.
  nature,

  /// Fantasy category.
  fantasy,

  /// Mandala category.
  mandala,

  /// Kids category.
  kids,

  /// Fun category.
  fun,

  /// People category.
  people,

  /// Flowers category.
  flowers,

  /// Patterns category.
  patterns,

  /// Abstract category.
  abstract,

  /// City category.
  city;

  /// Parses a stored category value, returning `null` for unknown values.
  ///
  /// Unknown categories are ignored instead of failing the whole response, so
  /// a category added on the server does not break older clients. The UI-only
  /// [all] value is not a stored category and is rejected as well.
  static ContourCategory? tryParse(String value) {
    if (value == all.name) {
      return null;
    }
    for (final ContourCategory category in values) {
      if (category.name == value) {
        return category;
      }
    }
    return null;
  }
}
