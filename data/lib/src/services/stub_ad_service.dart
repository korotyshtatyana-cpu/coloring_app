import 'package:core/core.dart';
import 'package:flutter/widgets.dart';

import 'ad_service.dart';
import 'rewarded_ad_outcome.dart';

/// No-op [AdService] used where the ad SDK is not wired up yet.
///
/// Keeps the rest of the application free of platform checks: a missing ad
/// provider simply disables ads instead of breaking the flow.
class StubAdService implements AdService {
  /// Creates a [StubAdService].
  const StubAdService();

  @override
  Future<void> initialize() async {}

  @override
  bool get isInitialized => false;

  @override
  Future<RewardedAdOutcome> showRewardedAd({String? contourId}) async {
    appLocator<AppLogger>().warning(
      '[Monetization] Rewarded ad failed: contour=${contourId ?? 'unknown'}, '
      'error=ads are not supported on this platform',
    );
    return RewardedAdOutcome.unavailable;
  }

  @override
  Widget? buildBanner() => null;
}
