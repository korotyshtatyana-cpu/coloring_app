/// Abstract crash reporting interface.
///
/// Implementations process application errors and diagnostic breadcrumbs,
/// forwarding them to remote monitoring providers or no-op sinks.
abstract interface class CrashReporter {
  /// Associates the current user session with [userId], or clears it when `null`.
  void setUserId(String? userId);

  /// Sets a custom key-value diagnostic pair.
  void setCustomKey(String key, Object value);

  /// Records a non-fatal or fatal error with optional [reason] and [stackTrace].
  void recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  });

  /// Logs a breadcrumb or diagnostic message.
  void log(String message);
}
