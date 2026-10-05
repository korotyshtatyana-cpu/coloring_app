/// Access level granted to the current user for a single project.
enum ProjectAccess {
  /// The project is fully blocked and cannot be opened.
  locked,

  /// The project can be opened and edited.
  unlocked,

  /// The project can be opened but not edited.
  viewOnly,
}
