import 'package:logger/logger.dart';

import '../services/crash_reporter.dart';
import '../services/pii_scrubber.dart';

/// Wrapper around the [logger] package providing application-level logging.
class AppLogger {
  final Logger _logger;
  CrashReporter? _crashReporter;

  /// Creates a logger with default PrettyPrinter settings.
  AppLogger()
      : _logger = Logger(
          printer: PrettyPrinter(
            methodCount: 2,
            errorMethodCount: 8,
            lineLength: 100,
            colors: true,
            printEmojis: true,
            dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
          ),
        );

  /// Connects a [CrashReporter] sink to forward logged events.
  void setCrashReporter(CrashReporter? crashReporter) {
    _crashReporter = crashReporter;
  }

  /// Logs a verbose message.
  void verbose(dynamic message, [Object? error, StackTrace? stackTrace]) {
    _logger.t(message, error: error, stackTrace: stackTrace);
  }

  /// Logs a debug message.
  void debug(dynamic message, [Object? error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Logs an info message.
  void info(dynamic message, [Object? error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
    final CrashReporter? reporter = _crashReporter;
    if (reporter != null) {
      try {
        reporter.log(PiiScrubber.scrub(message.toString()));
      } catch (_) {}
    }
  }

  /// Logs a warning message.
  void warning(dynamic message, [Object? error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
    final CrashReporter? reporter = _crashReporter;
    if (reporter != null) {
      try {
        reporter.log(PiiScrubber.scrub(message.toString()));
      } catch (_) {}
    }
  }

  /// Logs an error message.
  void error(dynamic message, [Object? error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
    final CrashReporter? reporter = _crashReporter;
    if (reporter != null) {
      try {
        reporter.recordError(
          error ?? message,
          stackTrace,
          reason: PiiScrubber.scrub(message.toString()),
          fatal: false,
        );
      } catch (_) {}
    }
  }

  /// Logs a wtf (critical) message.
  void wtf(dynamic message, [Object? error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
    final CrashReporter? reporter = _crashReporter;
    if (reporter != null) {
      try {
        reporter.recordError(
          error ?? message,
          stackTrace,
          reason: PiiScrubber.scrub(message.toString()),
          fatal: true,
        );
      } catch (_) {}
    }
  }
}
