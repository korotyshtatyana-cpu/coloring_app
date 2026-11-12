import 'package:core/core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Implementation of [CrashReporter] using Firebase Crashlytics.
class FirebaseCrashReporter implements CrashReporter {
  final FirebaseCrashlytics _crashlytics;

  /// Creates a [FirebaseCrashReporter] using optional custom [_crashlytics] instance.
  FirebaseCrashReporter({FirebaseCrashlytics? crashlytics})
      : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  @override
  void setUserId(String? userId) {
    _crashlytics.setUserIdentifier(userId ?? '');
  }

  @override
  void setCustomKey(String key, Object value) {
    if (value is int) {
      _crashlytics.setCustomKey(key, value);
    } else if (value is double) {
      _crashlytics.setCustomKey(key, value);
    } else if (value is bool) {
      _crashlytics.setCustomKey(key, value);
    } else if (value is String) {
      _crashlytics.setCustomKey(key, value);
    } else {
      _crashlytics.setCustomKey(key, value.toString());
    }
  }

  @override
  void recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) {
    _crashlytics.recordError(
      error,
      stackTrace,
      reason: reason,
      fatal: fatal,
    );
  }

  @override
  void log(String message) {
    _crashlytics.log(message);
  }
}
