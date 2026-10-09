import 'package:core/core.dart';
import 'package:domain/domain.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data.dart';

/// Data dependency injection setup.
abstract class DataDI {
  /// Initializes all data-level dependencies in the global [appLocator].
  static Future<void> initDependencies() async {
    final config = appLocator<AppConfig>();

    await _initApi(config);
    _initProviders();
    await _initServices(config);
    _initRepositories(config);
    await _initBilling();
  }

  static Future<void> _initApi(AppConfig config) async {
    final supabaseProvider = SupabaseProvider(config: config);
    await supabaseProvider.initialize();
    appLocator.registerSingleton<SupabaseProvider>(supabaseProvider);
  }

  static void _initProviders() {
    appLocator.registerLazySingleton<AppDatabase>(AppDatabase.new);
  }

  static Future<void> _initServices(AppConfig config) async {
    final preferences = await SharedPreferences.getInstance();
    appLocator.registerSingleton<SharedPreferences>(preferences);
  }

  static void _initRepositories(AppConfig config) {
    appLocator.registerLazySingleton<ShareRepository>(() => const ShareRepositoryImpl());

    appLocator.registerSingleton<BillingPlatform>(BillingPlatformFactory.create());

    appLocator.registerLazySingleton<AuthRemoteProvider>(
      () => AuthRemoteProvider(
        client: appLocator<SupabaseProvider>().client,
        googleWebClientId: config.googleWebClientId,
      ),
    );

    appLocator.registerLazySingleton<GalleryRemoteProvider>(
      () => GalleryRemoteProvider(client: appLocator<SupabaseProvider>().client),
    );

    appLocator.registerLazySingleton<GalleryLocalProvider>(
      () => GalleryLocalProvider(database: appLocator<AppDatabase>()),
    );

    appLocator.registerLazySingleton<FeedbackRemoteProvider>(
      () => FeedbackRemoteProvider(client: appLocator<SupabaseProvider>().client),
    );

    appLocator.registerLazySingleton<CanvasRemoteProvider>(
      () => CanvasRemoteProvider(client: appLocator<SupabaseProvider>().client),
    );

    appLocator.registerLazySingleton<CanvasLocalProvider>(
      () => CanvasLocalProvider(database: appLocator<AppDatabase>()),
    );

    appLocator.registerLazySingleton<MonetizationRemoteProvider>(
      () => MonetizationRemoteProvider(client: appLocator<SupabaseProvider>().client),
    );

    appLocator.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        remoteProvider: appLocator<AuthRemoteProvider>(),
        localProvider: appLocator<CanvasLocalProvider>(),
      ),
    );

    appLocator.registerLazySingleton<GalleryRepository>(
      () => GalleryRepositoryImpl(
        remoteProvider: appLocator<GalleryRemoteProvider>(),
        localProvider: appLocator<GalleryLocalProvider>(),
      ),
    );

    appLocator.registerLazySingleton<MonetizationRepository>(
      () => MonetizationRepositoryImpl(
        remoteProvider: appLocator<MonetizationRemoteProvider>(),
        billingPlatform: appLocator<BillingPlatform>(),
      ),
    );

    appLocator.registerLazySingleton<CanvasRepository>(
      () => CanvasRepositoryImpl(
        remoteProvider: appLocator<CanvasRemoteProvider>(),
        localProvider: appLocator<CanvasLocalProvider>(),
        authRemoteProvider: appLocator<AuthRemoteProvider>(),
      ),
    );

    appLocator.registerLazySingleton<SettingsRepository>(
      () => SettingsRepositoryImpl(preferences: appLocator<SharedPreferences>()),
    );

    appLocator.registerLazySingleton<FeedbackRepository>(
      () => FeedbackRepositoryImpl(remoteProvider: appLocator<FeedbackRemoteProvider>()),
    );
  }

  static Future<void> _initBilling() async {
    try {
      // Resolve the repository eagerly so its purchase subscription is
      // established before unfinished transactions are re-delivered.
      appLocator<MonetizationRepository>();
      await appLocator<BillingPlatform>().initialize();
    } on UnimplementedError catch (_) {
      appLocator<AppLogger>().warning('Billing platform is not implemented yet');
    } on UnsupportedError catch (_) {
      appLocator<AppLogger>().warning('Billing is not supported on this platform');
    }
  }
}
