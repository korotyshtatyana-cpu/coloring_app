import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../constants/request_constants.dart';
import '../models/subscription_model.dart';

/// Two-level cache (in-memory plus SharedPreferences) for the subscription
/// state used by the gallery.
///
/// The gallery resolves access on every open; without a cache that means a
/// Supabase round-trip each time. The cache absorbs those repeated reads while
/// staying safe: a subscription is only served while it is still active by its
/// own `expires_at`, and the whole cache is invalidated after every confirmed
/// purchase or restore.
class SubscriptionCache {
  final SharedPreferences _preferences;

  static const String _subscriptionKey = 'monetization_cached_subscription';
  static const String _subscriptionFetchedAtKey =
      'monetization_cached_subscription_at';
  static const String _noAdsKey = 'monetization_cached_no_ads';
  static const String _noAdsFetchedAtKey = 'monetization_cached_no_ads_at';

  SubscriptionModel? _subscription;
  DateTime? _subscriptionFetchedAt;
  bool? _noAds;
  DateTime? _noAdsFetchedAt;
  bool _loaded = false;

  /// Creates a cache backed by [_preferences].
  SubscriptionCache({required this._preferences});

  /// Returns the cached subscription for [userId] when it is still fresh and
  /// active, otherwise `null` so the caller queries the server again.
  SubscriptionModel? readSubscription(String userId) {
    _ensureLoaded();
    final SubscriptionModel? model = _subscription;
    if (model == null || model.userId != userId) {
      return null;
    }
    if (!_isFresh(_subscriptionFetchedAt)) {
      return null;
    }
    if (!model.isActive || !model.expiresAt.isAfter(DateTime.now())) {
      return null;
    }
    return model;
  }

  /// Returns the last stored subscription for [userId], whatever its state.
  ///
  /// Used to detect an active-to-none transition so a `subscription_expired`
  /// event can be emitted exactly once.
  SubscriptionModel? readLastSubscription(String userId) {
    _ensureLoaded();
    final SubscriptionModel? model = _subscription;
    if (model == null || model.userId != userId) {
      return null;
    }
    return model;
  }

  /// Stores the latest subscription for [userId], `null` when the user has none.
  void writeSubscription(String userId, SubscriptionModel? model) {
    _ensureLoaded();
    _subscription = model;
    _subscriptionFetchedAt = DateTime.now();

    if (model == null) {
      _preferences.remove(_subscriptionKey);
    } else {
      _preferences.setString(_subscriptionKey, jsonEncode(model.toJson()));
    }
    _preferences.setInt(
      _subscriptionFetchedAtKey,
      _subscriptionFetchedAt!.millisecondsSinceEpoch,
    );
  }

  /// Returns the cached No Ads flag when it is still fresh, otherwise `null`.
  bool? readNoAds(String userId) {
    _ensureLoaded();
    if (_noAds == null || !_isFresh(_noAdsFetchedAt)) {
      return null;
    }
    return _noAds;
  }

  /// Stores the latest No Ads flag for [userId].
  void writeNoAds(String userId, bool purchased) {
    _ensureLoaded();
    _noAds = purchased;
    _noAdsFetchedAt = DateTime.now();
    _preferences.setBool(_noAdsKey, purchased);
    _preferences.setInt(
      _noAdsFetchedAtKey,
      _noAdsFetchedAt!.millisecondsSinceEpoch,
    );
  }

  /// Drops every cached value, forcing the next read to hit the server.
  void invalidate() {
    _ensureLoaded();
    _subscription = null;
    _subscriptionFetchedAt = null;
    _noAds = null;
    _noAdsFetchedAt = null;
    _preferences.remove(_subscriptionKey);
    _preferences.remove(_subscriptionFetchedAtKey);
    _preferences.remove(_noAdsKey);
    _preferences.remove(_noAdsFetchedAtKey);
  }

  bool _isFresh(DateTime? fetchedAt) {
    if (fetchedAt == null) {
      return false;
    }
    return DateTime.now().difference(fetchedAt) < RequestConstants.monetizationCacheTtl;
  }

  void _ensureLoaded() {
    if (_loaded) {
      return;
    }
    _loaded = true;

    final String? raw = _preferences.getString(_subscriptionKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        _subscription = SubscriptionModel.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      } catch (_) {
        _subscription = null;
      }
    }
    _subscriptionFetchedAt = _readTimestamp(_subscriptionFetchedAtKey);
    _noAds = _preferences.getBool(_noAdsKey);
    _noAdsFetchedAt = _readTimestamp(_noAdsFetchedAtKey);
  }

  DateTime? _readTimestamp(String key) {
    final int? millis = _preferences.getInt(key);
    return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }
}
