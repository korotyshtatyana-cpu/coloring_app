/// Persistent storage for the colors selected most recently by the user.
///
/// Colors are stored as `#RRGGBB` strings. The dialog owns no copy of the
/// service: it is provided once at the screen entry point and read by the
/// color picker widgets.
abstract interface class RecentColorsService {
  /// Maximum number of colors kept in the recent colors row.
  static const int maxColors = 10;

  /// Returns the saved colors, newest first.
  ///
  /// An empty list is returned when nothing was saved yet.
  Future<List<String>> load();

  /// Moves [hex] to the front of the list, drops duplicates and saves it.
  ///
  /// Returns the updated list, newest first. Invalid values leave the saved
  /// list unchanged.
  Future<List<String>> remember(String hex);
}
