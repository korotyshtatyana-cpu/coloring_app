import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum Flavor {
  prod,
  dev,
}

class AppConfig {
  final Flavor flavor;
  final String baseUrl;
  final String webSocketUrl;

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String googleWebClientId;

  final String appsFlyerDevKey;
  final String appleAppId;

  const AppConfig({
    required this.flavor,
    required this.baseUrl,
    required this.webSocketUrl,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.googleWebClientId,
    required this.appsFlyerDevKey,
    required this.appleAppId,
  });

  factory AppConfig.fromFlavor(Flavor flavor) {
    String baseUrl;
    String webSocketUrl;
    String supabaseUrl;
    String supabaseAnonKey;
    String googleWebClientId;
    String appsFlyerDevKey;
    String appleAppId;

    switch (flavor) {
      case Flavor.prod:
        baseUrl = '';
        webSocketUrl = '';
        supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
        supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
        googleWebClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '';
        appsFlyerDevKey = dotenv.env['APPSFLYER_DEV_KEY'] ?? '';
        appleAppId =
            (Platform.isIOS
                ? dotenv.env['APPSFLYER_IOS_APP_ID']
                : dotenv.env['APPSFLYER_ANDROID_APP_ID']) ??
                '';
        break;

      case Flavor.dev:
        baseUrl = '';
        webSocketUrl = '';
        supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
        supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
        googleWebClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '';
        appsFlyerDevKey = dotenv.env['APPSFLYER_DEV_KEY'] ?? '';
        appleAppId =
            (Platform.isIOS
                ? dotenv.env['APPSFLYER_IOS_APP_ID']
                : dotenv.env['APPSFLYER_ANDROID_APP_ID']) ??
                '';
        break;
    }

    return AppConfig(
      flavor: flavor,
      baseUrl: baseUrl,
      webSocketUrl: webSocketUrl,
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
      googleWebClientId: googleWebClientId,
      appsFlyerDevKey: appsFlyerDevKey,
      appleAppId: appleAppId,
    );
  }
}