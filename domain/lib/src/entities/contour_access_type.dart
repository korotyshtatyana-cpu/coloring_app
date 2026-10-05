/// Monetization access type of a coloring project.
enum ContourAccessType {
  /// Available to everyone without ads and without payment.
  ///
  /// Mapped to the `free` database value.
  free('free'),

  /// Requires watching a rewarded video before every open.
  ///
  /// Mapped to the `rewarded` database value.
  rewarded('rewarded'),

  /// Requires an individual purchase or an active Premium subscription.
  ///
  /// Mapped to the `paid` database value.
  paid('paid');

  /// Value stored in the database `contours.access_type` column.
  final String dbValue;

  const ContourAccessType(this.dbValue);

  /// Returns the access type matching the given database [value].
  ///
  /// Returns `null` when [value] is not recognized.
  static ContourAccessType? fromDb(String value) {
    for (final ContourAccessType type in ContourAccessType.values) {
      if (type.dbValue == value) {
        return type;
      }
    }
    return null;
  }
}
