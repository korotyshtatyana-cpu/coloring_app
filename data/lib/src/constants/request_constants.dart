/// Constants used for remote data requests and table names.
abstract final class RequestConstants {
  // Supabase table names
  static const String usersTable = 'users';
  static const String contoursTable = 'contours';
  static const String favoritesTable = 'favorites';
  static const String projectsTable = 'projects';

  // Supabase query columns
  static const String selectAll = '*';
  static const String selectContourId = 'contour_id';
  static const String selectProjectData = 'contour_id, data, last_opened';

  // Supabase columns
  static const String createdAtColumn = 'created_at';
  static const String categoryColumn = 'category';
  static const String userIdColumn = 'user_id';
  static const String contourIdColumn = 'contour_id';
  static const String lastOpenedColumn = 'last_opened';
  static const String dataColumn = 'data';

  // Supabase query parameters
  static const String limitParam = 'limit';
  static const String offsetParam = 'offset';
  static const String orderParam = 'order';
  static const String categoryParam = 'category';
  static const String userIdParam = 'user_id';
  static const String contourIdParam = 'contour_id';
  static const String onConflictUserContour = '(user_id, contour_id)';

  // Error messages
  static const String userNotAuthenticated = 'User not authenticated';
  static const String googleSignInAborted = 'Google sign in aborted';
  static const String googleIdTokenNull = 'Google idToken is null';
  static const String googleSignInFailed = 'Failed to sign in with Google';
  static const String appleIdTokenNull = 'Apple idToken is null';
  static const String appleSignInFailed = 'Failed to sign in with Apple';
  static const String platformNotSupported = 'Platform is not supported';
  static const String silentSignInNotAvailable =
      'Silent sign-in is not available';

  // Export file name
  static const String exportFilePrefix = 'coloring_pro';
}
