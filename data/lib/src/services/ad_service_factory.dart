import 'dart:io';

import 'package:core/core.dart';

import 'ad_service.dart';
import 'stub_ad_service.dart';
import 'yandex_ad_service.dart';

/// Creates the [AdService] matching the current operating system.
abstract final class AdServiceFactory {
  /// Returns the ad service for this device.
  ///
  /// Android uses the fully implemented [YandexAdService]; every other
  /// platform returns the [StubAdService], which disables ads.
  static AdService create({
    required String rewardedUnitId,
    required String bannerUnitId,
    required AnalyticsService analytics,
  }) {
    if (Platform.isAndroid) {
      return YandexAdService(
        rewardedUnitId: rewardedUnitId,
        bannerUnitId: bannerUnitId,
        analytics: analytics,
      );
    }
    return const StubAdService();
  }
}
