import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Flavor environments supported by the application.
enum Flavor {
  prod,
  dev,
}

/// Holds application configuration parameters loaded from environment files.
class AppConfig {
  /// Build flavor of the running app.
  final Flavor flavor;

  /// Supabase project URL.
  final String supabaseUrl;

  /// Supabase anonymous key.
  final String supabaseAnonKey;

  /// Google OAuth Web Client ID.
  final String googleWebClientId;

  /// AppsFlyer Developer Key.
  final String appsFlyerDevKey;

  /// Apple Application ID.
  final String appleAppId;

  /// Yandex Rewarded Ad Unit ID.
  final String yandexAdsRewardedUnitId;

  /// Yandex Banner Ad Unit ID.
  final String yandexAdsBannerUnitId;

  /// Firebase Project ID.
  final String firebaseProjectId;

  /// Firebase Messaging Sender ID.
  final String firebaseSenderId;

  /// Firebase Storage Bucket.
  final String firebaseStorageBucket;

  /// Firebase Android API Key.
  final String firebaseApiKeyAndroid;

  /// Firebase Android App ID.
  final String firebaseAppIdAndroid;

  /// Firebase iOS API Key.
  final String firebaseApiKeyIos;

  /// Firebase iOS App ID.
  final String firebaseAppIdIos;

  /// Creates an [AppConfig] instance.
  const AppConfig({
    required this.flavor,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.googleWebClientId,
    required this.appsFlyerDevKey,
    required this.appleAppId,
    required this.yandexAdsRewardedUnitId,
    required this.yandexAdsBannerUnitId,
    required this.firebaseProjectId,
    required this.firebaseSenderId,
    required this.firebaseStorageBucket,
    required this.firebaseApiKeyAndroid,
    required this.firebaseAppIdAndroid,
    required this.firebaseApiKeyIos,
    required this.firebaseAppIdIos,
  });

  /// Factory creating an [AppConfig] from `.env` keys for [flavor].
  factory AppConfig.fromFlavor(Flavor flavor) {
    return AppConfig(
      flavor: flavor,
      supabaseUrl: dotenv.env['SUPABASE_URL'] ?? '',
      supabaseAnonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
      googleWebClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '',
      appsFlyerDevKey: dotenv.env['APPSFLYER_DEV_KEY'] ?? '',
      appleAppId: (Platform.isIOS
              ? dotenv.env['APPSFLYER_IOS_APP_ID']
              : dotenv.env['APPSFLYER_ANDROID_APP_ID']) ??
          '',
      yandexAdsRewardedUnitId: dotenv.env['YANDEX_ADS_REWARDED_UNIT_ID'] ?? '',
      yandexAdsBannerUnitId: dotenv.env['YANDEX_ADS_BANNER_UNIT_ID'] ?? '',
      firebaseProjectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
      firebaseSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
      firebaseStorageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
      firebaseApiKeyAndroid: dotenv.env['FIREBASE_API_KEY_ANDROID'] ?? '',
      firebaseAppIdAndroid: dotenv.env['FIREBASE_APP_ID_ANDROID'] ?? '',
      firebaseApiKeyIos: dotenv.env['FIREBASE_API_KEY_IOS'] ?? '',
      firebaseAppIdIos: dotenv.env['FIREBASE_APP_ID_IOS'] ?? '',
    );
  }

  /// Returns `true` if required Firebase keys for the current platform are present.
  bool get hasFirebaseConfig {
    if (firebaseProjectId.isEmpty || firebaseSenderId.isEmpty) {
      return false;
    }
    if (Platform.isAndroid) {
      return firebaseApiKeyAndroid.isNotEmpty &&
          firebaseAppIdAndroid.isNotEmpty;
    }
    if (Platform.isIOS) {
      return firebaseApiKeyIos.isNotEmpty && firebaseAppIdIos.isNotEmpty;
    }
    return false;
  }
}
