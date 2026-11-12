import 'crash_reporter.dart';

/// Fallback no-op implementation of [CrashReporter].
class NoopCrashReporter implements CrashReporter {
  /// Creates a [NoopCrashReporter].
  const NoopCrashReporter();

  @override
  void setUserId(String? userId) {}

  @override
  void setCustomKey(String key, Object value) {}

  @override
  void recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) {}

  @override
  void log(String message) {}
}
