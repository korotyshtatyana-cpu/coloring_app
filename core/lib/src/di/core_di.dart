import '../../core.dart';

/// Core dependency injection setup.
abstract class CoreDi {
  /// Initializes core dependencies in the global [appLocator].
  static void init(Flavor flavor) {
    appLocator.registerSingleton<AppConfig>(
      AppConfig.fromFlavor(flavor),
    );

    appLocator.registerLazySingleton<AppLogger>(AppLogger.new);

    appLocator.registerLazySingleton<AnalyticsService>(
      () => AnalyticsService(logger: appLocator<AppLogger>()),
    );
  }
}
