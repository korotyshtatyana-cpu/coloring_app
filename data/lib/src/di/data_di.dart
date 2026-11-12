import 'dart:io';

import 'package:core/core.dart';
import 'package:domain/domain.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data.dart';

/// Data dependency injection setup.
abstract class DataDI {
  /// Initializes all data-level dependencies in the global [appLocator].
  static Future<void> initDependencies() async {
    final config = appLocator<AppConfig>();

    await _initCrashlytics(config);
    await _initApi(config);
    _initProviders();
    await _initServices(config);
    _initRepositories(config);
    await _initBilling();
    await _initAds();
  }

  static Future<void> _initCrashlytics(AppConfig config) async {
    if (config.hasFirebaseConfig) {
      try {
        await Firebase.initializeApp(
          options: FirebaseOptionsFactory.create(config),
        );
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
          !kDebugMode,
        );
        final CrashReporter reporter = FirebaseCrashReporter();
        appLocator.registerSingleton<CrashReporter>(reporter);

        reporter.setCustomKey('flavor', config.flavor.name);
        final String appVersion = await AppVersion.version;
        final String buildNumber = await AppVersion.buildNumber;
        reporter.setCustomKey('app_version', appVersion);
        reporter.setCustomKey('build_number', buildNumber);
        reporter.setCustomKey('platform', Platform.operatingSystem);
        reporter.setCustomKey('locale', Platform.localeName);

        appLocator<AppLogger>().setCrashReporter(reporter);
        return;
      } catch (error, stackTrace) {
        ErrorHandler.report(error, stackTrace);
        appLocator<AppLogger>().warning(
          'Firebase Crashlytics init failed; using NoopCrashReporter',
        );
      }
    } else {
      appLocator<AppLogger>().warning(
        'Firebase Crashlytics is not configured; using NoopCrashReporter',
      );
    }

    const CrashReporter fallback = NoopCrashReporter();
    appLocator.registerSingleton<CrashReporter>(fallback);
    appLocator<AppLogger>().setCrashReporter(fallback);
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
    appLocator.registerLazySingleton<ShareRepository>(
      () => const ShareRepositoryImpl(),
    );

    appLocator.registerLazySingleton<SubscriptionCache>(
      () => SubscriptionCache(preferences: appLocator<SharedPreferences>()),
    );

    appLocator.registerSingleton<BillingPlatform>(
      BillingPlatformFactory.create(),
    );

    appLocator.registerSingleton<AdService>(
      AdServiceFactory.create(
        rewardedUnitId: config.yandexAdsRewardedUnitId,
        bannerUnitId: config.yandexAdsBannerUnitId,
        analytics: appLocator<AnalyticsService>(),
      ),
    );

    appLocator.registerLazySingleton<AuthRemoteProvider>(
      () => AuthRemoteProvider(
        client: appLocator<SupabaseProvider>().client,
        googleWebClientId: config.googleWebClientId,
      ),
    );

    appLocator.registerLazySingleton<GalleryRemoteProvider>(
      () =>
          GalleryRemoteProvider(client: appLocator<SupabaseProvider>().client),
    );

    appLocator.registerLazySingleton<GalleryLocalProvider>(
      () => GalleryLocalProvider(database: appLocator<AppDatabase>()),
    );

    appLocator.registerLazySingleton<FeedbackRemoteProvider>(
      () =>
          FeedbackRemoteProvider(client: appLocator<SupabaseProvider>().client),
    );

    appLocator.registerLazySingleton<CanvasRemoteProvider>(
      () => CanvasRemoteProvider(client: appLocator<SupabaseProvider>().client),
    );

    appLocator.registerLazySingleton<CanvasLocalProvider>(
      () => CanvasLocalProvider(database: appLocator<AppDatabase>()),
    );

    appLocator.registerLazySingleton<MonetizationRemoteProvider>(
      () => MonetizationRemoteProvider(
        client: appLocator<SupabaseProvider>().client,
      ),
    );

    appLocator.registerLazySingleton<RefundMonitor>(
      () => SupabaseRefundMonitor(
        client: appLocator<SupabaseProvider>().client,
        logger: appLocator<AppLogger>(),
      ),
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
        refundMonitor: appLocator<RefundMonitor>(),
        subscriptionCache: appLocator<SubscriptionCache>(),
        analytics: appLocator<AnalyticsService>(),
        logger: appLocator<AppLogger>(),
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
      () =>
          SettingsRepositoryImpl(preferences: appLocator<SharedPreferences>()),
    );

    appLocator.registerLazySingleton<FeedbackRepository>(
      () => FeedbackRepositoryImpl(
        remoteProvider: appLocator<FeedbackRemoteProvider>(),
      ),
    );
  }

  static Future<void> _initBilling() async {
    try {
      appLocator<MonetizationRepository>();
      await appLocator<BillingPlatform>().initialize();
    } on UnimplementedError catch (_) {
      appLocator<AppLogger>().warning(
        'Billing platform is not implemented yet',
      );
    } on UnsupportedError catch (_) {
      appLocator<AppLogger>().warning(
        'Billing is not supported on this platform',
      );
    }
  }

  static Future<void> _initAds() async {
    try {
      await appLocator<AdService>().initialize();
    } catch (error, stackTrace) {
      ErrorHandler.report(error, stackTrace);
      appLocator<AppLogger>().warning('Ad SDK initialization failed');
    }
  }
}
