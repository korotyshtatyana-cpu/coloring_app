import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/widgets.dart';
import 'package:yandex_mobileads/mobile_ads.dart';

/// Sticky bottom banner rendered by the Yandex Mobile Ads SDK.
///
/// The banner is created lazily from the surrounding [MediaQuery] width so it
/// matches the current orientation, and is destroyed with the widget.
class YandexBannerAdView extends StatefulWidget {
  /// Yandex ad unit identifier of the banner placement.
  final String adUnitId;

  /// Creates a [YandexBannerAdView].
  const YandexBannerAdView({required this.adUnitId, super.key});

  @override
  State<YandexBannerAdView> createState() => _YandexBannerAdViewState();
}

class _YandexBannerAdViewState extends State<YandexBannerAdView> {
  BannerAd? _bannerAd;
  int? _width;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final int width = MediaQuery.sizeOf(context).width.toInt();
    if (_bannerAd == null || _width != width) {
      final BannerAd? previous = _bannerAd;
      if (previous != null) {
        unawaited(previous.destroy());
      }
      _width = width;
      _bannerAd = _createBannerAd(width);
    }
  }

  @override
  void dispose() {
    final BannerAd? bannerAd = _bannerAd;
    if (bannerAd != null) {
      unawaited(bannerAd.destroy());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BannerAd? bannerAd = _bannerAd;
    if (bannerAd == null) {
      return const SizedBox.shrink();
    }
    return AdWidget(bannerAd: bannerAd);
  }

  BannerAd _createBannerAd(int width) {
    return BannerAd(
      adUnitId: widget.adUnitId,
      adSize: BannerAdSize.sticky(width: width),
      adRequest: const AdRequest(),
      onAdFailedToLoad: (AdRequestError error) {
        appLocator<AppLogger>().warning(
          '[Monetization] Banner ad failed: error=${error.description}',
        );
      },
    );
  }
}
