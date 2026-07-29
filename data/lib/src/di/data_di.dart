import 'package:core/core.dart';
import 'package:domain/domain.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data.dart';

/// Data dependency injection setup.
abstract class DataDI {
  /// Initializes all data-level dependencies in the global [appLocator].
  static Future<void> initDependencies() async {
    await _initApi();
    _initProviders();
    _initServices();
    _initRepositories();
  }

  static Future<void> _initApi() async {
    final supabaseProvider = SupabaseProvider(
      config: appLocator<AppConfig>(),
    );
    await supabaseProvider.initialize();
    appLocator.registerSingleton<SupabaseProvider>(supabaseProvider);
  }

  static void _initProviders() {
    appLocator.registerLazySingleton<AppDatabase>(AppDatabase.new);
  }

  static Future<void> _initServices() async {
    appLocator.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn.instance);
    final preferences = await SharedPreferences.getInstance();
    appLocator.registerSingleton<SharedPreferences>(preferences);
  }

  static void _initRepositories() {
    appLocator.registerLazySingleton<ShareRepository>(
      () => const ShareRepositoryImpl(),
    );

    appLocator.registerLazySingleton<AuthRemoteProvider>(
      () => AuthRemoteProvider(
        client: appLocator<SupabaseProvider>().client,
        googleSignIn: appLocator<GoogleSignIn>(),
      ),
    );

    appLocator.registerLazySingleton<GalleryRemoteProvider>(
      () => GalleryRemoteProvider(
        client: appLocator<SupabaseProvider>().client,
      ),
    );

    appLocator.registerLazySingleton<GalleryLocalProvider>(
      () => GalleryLocalProvider(
        database: appLocator<AppDatabase>(),
      ),
    );

    appLocator.registerLazySingleton<CanvasRemoteProvider>(
      () => CanvasRemoteProvider(
        client: appLocator<SupabaseProvider>().client,
      ),
    );

    appLocator.registerLazySingleton<CanvasLocalProvider>(
      () => CanvasLocalProvider(
        database: appLocator<AppDatabase>(),
      ),
    );

    appLocator.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        remoteProvider: appLocator<AuthRemoteProvider>(),
      ),
    );

    appLocator.registerLazySingleton<GalleryRepository>(
      () => GalleryRepositoryImpl(
        remoteProvider: appLocator<GalleryRemoteProvider>(),
        localProvider: appLocator<GalleryLocalProvider>(),
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
      () => SettingsRepositoryImpl(
        preferences: appLocator<SharedPreferences>(),
      ),
    );
  }
}
