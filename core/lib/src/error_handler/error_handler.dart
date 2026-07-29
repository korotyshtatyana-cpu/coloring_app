/// Centralized application error handler.
///
/// The default implementation only prints to the console. The actual
/// application should register a delegate via [setDelegate] to plug in logging,
/// reporting and UI presentation (e.g. from the app-level error handler).
class ErrorHandler {
  static void Function(Object error, StackTrace stackTrace, String? message)?
      _delegate;

  /// Registers a [delegate] that will be called by [report] and [handleError].
  ///
  /// Passing `null` removes the delegate and restores the default print behavior.
  static void setDelegate(
    void Function(Object error, StackTrace stackTrace, String? message)? delegate,
  ) {
    _delegate = delegate;
  }

  /// Reports an [error] with optional [stackTrace] and [message].
  ///
  /// Use this method from business logic (e.g. BLoCs) to log and report errors
  /// without triggering any UI. If a delegate is registered, it is invoked;
  /// otherwise the error is printed to the console as a fallback.
  static void report(
    Object error,
    StackTrace stackTrace, {
    String? message,
  }) {
    _dispatch(error, stackTrace, message);
  }

  /// Handles an [error] with optional [stackTrace] and [message].
  ///
  /// This is a convenience alias for [report]. The actual presentation of the
  /// error to the user should be handled by the UI layer based on BLoC state.
  static void handleError(
    Object error,
    StackTrace stackTrace, [
    String? customMessage,
  ]) {
    _dispatch(error, stackTrace, customMessage);
  }

  static void _dispatch(
    Object error,
    StackTrace stackTrace,
    String? message,
  ) {
    if (_delegate != null) {
      _delegate!(error, stackTrace, message);
      return;
    }

    // ignore: avoid_print
    print('Error: $error');
    // ignore: avoid_print
    print('StackTrace: $stackTrace');
  }
}
