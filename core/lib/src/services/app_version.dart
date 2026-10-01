import 'package:package_info_plus/package_info_plus.dart';

/// Provides the build metadata of the running application.
abstract final class AppVersion {
  static Future<PackageInfo>? _info;

  /// Returns the platform package info, loading it once and caching it.
  static Future<PackageInfo> get info => _info ??= PackageInfo.fromPlatform();

  /// Returns the build number, e.g. `15` for `1.0.0+15`.
  /// Returns an empty string when the platform does not report one.
  static Future<String> get buildNumber async =>
      (await info).buildNumber.trim();

  /// Returns the semantic version without the build number, e.g. `1.0.0`.
  static Future<String> get version async => (await info).version;
}
