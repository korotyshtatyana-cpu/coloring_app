import 'dart:io';

import 'package:core/core.dart';
import 'package:firebase_core/firebase_core.dart';

/// Factory building platform-specific [FirebaseOptions] from [AppConfig].
abstract final class FirebaseOptionsFactory {
  /// Builds [FirebaseOptions] for the current platform from [config].
  ///
  /// Throws [StateError] if required keys are missing or incomplete.
  static FirebaseOptions create(AppConfig config) {
    if (!config.hasFirebaseConfig) {
      throw StateError(
        'Firebase configuration is missing or incomplete for '
        '${config.flavor.name}',
      );
    }

    if (Platform.isAndroid) {
      return FirebaseOptions(
        apiKey: config.firebaseApiKeyAndroid,
        appId: config.firebaseAppIdAndroid,
        messagingSenderId: config.firebaseSenderId,
        projectId: config.firebaseProjectId,
        storageBucket: config.firebaseStorageBucket.isNotEmpty
            ? config.firebaseStorageBucket
            : null,
      );
    }

    if (Platform.isIOS) {
      return FirebaseOptions(
        apiKey: config.firebaseApiKeyIos,
        appId: config.firebaseAppIdIos,
        messagingSenderId: config.firebaseSenderId,
        projectId: config.firebaseProjectId,
        storageBucket: config.firebaseStorageBucket.isNotEmpty
            ? config.firebaseStorageBucket
            : null,
        iosBundleId: 'com.korotysh.tatyana.coloringpro',
      );
    }

    throw UnsupportedError(
      'Firebase options not supported on platform: ${Platform.operatingSystem}',
    );
  }
}
