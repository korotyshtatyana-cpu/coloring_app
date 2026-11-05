import 'package:flutter/widgets.dart';

import 'rewarded_ad_outcome.dart';

/// Abstraction over the platform advertising SDK.
///
/// The application always talks to this interface, so the SDK-specific details
/// stay behind it and the SDK can be swapped without touching the presentation
/// layer. Android uses the fully implemented [YandexAdService]; other platforms
/// fall back to [StubAdService] until a provider is wired up for them.
abstract class AdService {
  /// Prepares the ad SDK for serving ads.
  Future<void> initialize();

  /// Whether the ad SDK is ready to serve ads.
  bool get isInitialized;

  /// Shows a rewarded video and reports how it ended.
  ///
  /// [contourId] is used only for analytics/logging so the ad flow can be tied
  /// back to the project the user tried to open.
  Future<RewardedAdOutcome> showRewardedAd({String? contourId});

  /// Builds the gallery banner widget, or `null` when ads are unavailable.
  Widget? buildBanner();
}
