import 'package:core/core.dart';

/// Localized error message resolver.
abstract final class ErrorMessages {
  /// Returns a human-readable localized message for the given [error].
  static String getMessage(Object error) {
    if (error is String) {
      return error;
    }

    if (error is Exception) {
      return error.toString();
    }

    if (error is Error) {
      return error.toString();
    }

    return LocaleKeys.something_went_wrong.tr();
  }
}
