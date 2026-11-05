import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:yandex_mobileads/mobile_ads.dart';

import '../constants/ad_constants.dart';
import '../constants/analytics_events.dart';
import 'ad_service.dart';
import 'rewarded_ad_outcome.dart';
import 'yandex_banner_ad_view.dart';

// ---------------------------------------------------------------------------
// Platform configuration
//
// 1. android/app/src/main/AndroidManifest.xml
//    Internet permissions are merged by the plugins. The advertising ID
//    permission is declared so the SDK can use GAID for more relevant ads.
//
// 2. android/app/proguard-rules.pro
//    The Yandex SDK keep rules are already present (`com.yandex.mobile.ads.**`).
//    They are required because release builds enable R8 minification.
//
// 3. Yandex Mobile Ads dashboard (https://yandex.ru/dev/mobile-ads/)
//    - Register the application and obtain the App ID.
//    - Create a "Rewarded Video" ad unit and a "Banner" ad unit.
//    - Put the Ad Unit IDs into `env.sample` as `YANDEX_ADS_REWARDED_UNIT_ID`
//      and `YANDEX_ADS_BANNER_UNIT_ID`; they are read through `AppConfig`.
//      Empty IDs disable the corresponding ad format for that build.
//
// TODO(ads): wire a proper GDPR/user-consent flow and call
// `MobileAds.setUserConsent` / `MobileAds.setLocationConsent` accordingly
// before the first ad request in the region where it is required.
// ---------------------------------------------------------------------------

/// Yandex Mobile Ads implementation of [AdService] for Android.
///
/// Wraps the `yandex_mobileads` plugin and is the only ad class that talks to
/// the SDK directly.
class YandexAdService implements AdService {
  final String _rewardedUnitId;
  final String _bannerUnitId;
  final AnalyticsService _analytics;
  bool _isInitialized = false;
  Future<void>? _initFuture;
  RewardedAdLoader? _rewardedLoader;
  RewardedAd? _preloadedAd;
  Completer<RewardedAd?>? _loadCompleter;
  String? _loadError;

  /// Creates a [YandexAdService] with the configured ad unit identifiers.
  YandexAdService({
    required this._rewardedUnitId,
    required this._bannerUnitId,
    required this._analytics,
  });

  @override
  Future<void> initialize() {
    if (_isInitialized) {
      return Future<void>.value();
    }
    final Future<void>? pending = _initFuture;
    if (pending != null) {
      return pending;
    }
    final Future<void> future = _doInitialize();
    _initFuture = future;
    unawaited(
      future.whenComplete(() {
        if (!_isInitialized) {
          // Allow a later call to retry after a transient failure.
          _initFuture = null;
        }
      }),
    );
    return future;
  }

  Future<void> _doInitialize() async {
    try {
      await MobileAds.setLogging(kDebugMode);
      await MobileAds.initialize();
      _rewardedLoader = await RewardedAdLoader.create(
        onAdLoaded: _onRewardedAdLoaded,
        onAdFailedToLoad: _onRewardedAdFailedToLoad,
      );
      _isInitialized = true;

      final AppLogger logger = appLocator<AppLogger>();
      if (_rewardedUnitId.isEmpty) {
        logger.warning('YANDEX_ADS_REWARDED_UNIT_ID is empty; rewarded ads are disabled');
      }
      if (_bannerUnitId.isEmpty) {
        logger.warning('YANDEX_ADS_BANNER_UNIT_ID is empty; banner ads are disabled');
      }

      // Warm up the first rewarded ad so unlocking a project feels instant.
      if (_rewardedUnitId.isNotEmpty) {
        unawaited(_preloadRewardedAd());
      }
    } catch (error, stackTrace) {
      ErrorHandler.report(error, stackTrace);
      _isInitialized = false;
    }
  }

  @override
  bool get isInitialized => _isInitialized;

  void _onRewardedAdLoaded(RewardedAd ad) {
    _preloadedAd = ad;
    _completeLoad(ad);
  }

  void _onRewardedAdFailedToLoad(AdRequestError error) {
    _loadError = error.description;
    _completeLoad(null);
  }

  void _completeLoad(RewardedAd? ad) {
    final Completer<RewardedAd?>? completer = _loadCompleter;
    _loadCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete(ad);
    }
  }

  /// Starts or joins a rewarded-ad load and resolves with the loaded ad.
  Future<RewardedAd?> _preloadRewardedAd() {
    final RewardedAd? ready = _preloadedAd;
    if (ready != null) {
      return Future<RewardedAd?>.value(ready);
    }
    final Completer<RewardedAd?>? pending = _loadCompleter;
    if (pending != null) {
      return pending.future;
    }
    final RewardedAdLoader? loader = _rewardedLoader;
    if (!_isInitialized || loader == null || _rewardedUnitId.isEmpty) {
      return Future<RewardedAd?>.value();
    }

    final Completer<RewardedAd?> completer = Completer<RewardedAd?>();
    _loadCompleter = completer;
    _loadError = null;
    unawaited(
      loader
          .loadAd(adRequestConfiguration: AdRequestConfiguration(adUnitId: _rewardedUnitId))
          .catchError((Object error) {
            _loadError = error.toString();
            _completeLoad(null);
          }),
    );
    return completer.future;
  }

  @override
  Future<RewardedAdOutcome> showRewardedAd({String? contourId}) async {
    final AppLogger logger = appLocator<AppLogger>();
    final String contour = contourId ?? 'unknown';
    logger.debug('[Monetization] Rewarded ad started: contour=$contour');

    if (!_isInitialized) {
      await initialize();
    }

    if (!_isInitialized || _rewardedUnitId.isEmpty) {
      logger.warning(
        '[Monetization] Rewarded ad failed: contour=$contour, error=ads are not ready',
      );
      _analytics.logEvent(
        AnalyticsEvents.rewardedAdUnavailable,
        parameters: <String, Object?>{'reason': 'not_ready'},
      );
      return RewardedAdOutcome.unavailable;
    }

    RewardedAd? ad = _preloadedAd;
    _preloadedAd = null;
    if (ad == null) {
      try {
        ad = await _preloadRewardedAd().timeout(AdConstants.loadTimeout);
      } on TimeoutException {
        ad = null;
      }
      _preloadedAd = null;
    }

    if (ad == null) {
      logger.warning(
        '[Monetization] Rewarded ad failed: contour=$contour, '
        'error=${_loadError ?? 'load timeout'}',
      );
      _analytics.logEvent(
        AnalyticsEvents.rewardedAdUnavailable,
        parameters: <String, Object?>{
          'reason': _loadError == null ? 'load_timeout' : 'request_error',
        },
      );
      return RewardedAdOutcome.unavailable;
    }

    _loadError = null;
    _analytics.logEvent(
      AnalyticsEvents.rewardedAdShown,
      parameters: <String, Object?>{'ad_unit_id': _rewardedUnitId},
    );

    final Completer<RewardedAdOutcome> showCompleter = Completer<RewardedAdOutcome>();
    Reward? seenReward;
    void completeShow(RewardedAdOutcome outcome) {
      if (!showCompleter.isCompleted) {
        showCompleter.complete(outcome);
      }
    }

    try {
      // Without an event listener the plugin cannot observe the reward and
      // would report every impression as skipped.
      await ad.setAdEventListener(
        eventListener: RewardedAdEventListener(
          onRewarded: (Reward reward) => seenReward = reward,
          onAdDismissed: () => completeShow(
            seenReward == null ? RewardedAdOutcome.dismissed : RewardedAdOutcome.completed,
          ),
          onAdFailedToShow: (AdError error) {
            logger.warning(
              '[Monetization] Rewarded ad failed: contour=$contour, '
              'error=${error.description}',
            );
            completeShow(RewardedAdOutcome.unavailable);
          },
        ),
      );
      await ad.show();
      final RewardedAdOutcome outcome = await showCompleter.future;

      switch (outcome) {
        case RewardedAdOutcome.completed:
          logger.debug('[Monetization] Rewarded ad completed: contour=$contour');
          _analytics.logEvent(
            AnalyticsEvents.rewardedAdCompleted,
            parameters: <String, Object?>{'ad_unit_id': _rewardedUnitId},
          );
        case RewardedAdOutcome.dismissed:
          logger.warning('[Monetization] Rewarded ad skipped: contour=$contour');
          _analytics.logEvent(
            AnalyticsEvents.rewardedAdSkipped,
            parameters: <String, Object?>{'ad_unit_id': _rewardedUnitId},
          );
        case RewardedAdOutcome.unavailable:
          _analytics.logEvent(
            AnalyticsEvents.rewardedAdUnavailable,
            parameters: <String, Object?>{'reason': 'request_error'},
          );
      }
      return outcome;
    } on AdRequestError catch (error) {
      logger.warning(
        '[Monetization] Rewarded ad failed: contour=$contour, '
        'error=${error.description}',
      );
      _analytics.logEvent(
        AnalyticsEvents.rewardedAdUnavailable,
        parameters: <String, Object?>{'reason': 'request_error'},
      );
      return RewardedAdOutcome.unavailable;
    } catch (error, stackTrace) {
      ErrorHandler.report(error, stackTrace);
      logger.error('[Monetization] Rewarded ad failed: contour=$contour, error=$error');
      _analytics.logEvent(
        AnalyticsEvents.rewardedAdUnavailable,
        parameters: <String, Object?>{'reason': 'unexpected_error'},
      );
      return RewardedAdOutcome.unavailable;
    } finally {
      // Prepare the next ad in the background.
      unawaited(_preloadRewardedAd());
    }
  }

  @override
  Widget? buildBanner() {
    if (!_isInitialized || _bannerUnitId.isEmpty) {
      return null;
    }
    return YandexBannerAdView(adUnitId: _bannerUnitId);
  }
}
