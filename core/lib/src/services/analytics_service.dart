import '../utils/logger.dart';

/// Application analytics facade.
///
/// No third-party analytics SDK is wired up yet, so events are written to
/// [AppLogger] in a structured, greppable form. Wiring a real provider later
/// only requires changing this class, not any of its call sites.
class AnalyticsService {
  final AppLogger _logger;

  /// Creates an analytics service writing through [_logger].
  AnalyticsService({required this._logger});

  /// Logs an analytics [event] together with optional [parameters].
  void logEvent(String event, {Map<String, Object?>? parameters}) {
    final String details = parameters == null || parameters.isEmpty
        ? ''
        : ' ${parameters.entries.map((MapEntry<String, Object?> entry) {
            return '${entry.key}=${entry.value}';
          }).join(', ')}';
    _logger.info('[analytics] $event$details');
  }
}
