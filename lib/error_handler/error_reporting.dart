import 'package:core/core.dart';

/// Reports errors to the application logger.
abstract final class ErrorReporting {
  /// Reports [error] together with its [stackTrace] and optional [message].
  static void report(
    Object error,
    StackTrace stackTrace, [
    String? message,
  ]) {
    final String logMessage = message ?? 'Reporting error: $error';
    appLocator<AppLogger>().error(logMessage, error, stackTrace);
  }
}
