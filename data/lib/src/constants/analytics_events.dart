/// Names of the analytics events emitted by the monetization flows.
///
/// Keeping the names in one place makes it easy to grep, rename and later map
/// them onto a real analytics provider without touching call sites.
abstract final class AnalyticsEvents {
  /// The user started the store flow for a subscription.
  static const String purchaseStarted = 'monetization_purchase_started';

  /// The store confirmed and the server verified a purchase.
  static const String purchaseCompleted = 'monetization_purchase_completed';

  /// The store reported that the purchase is still awaiting confirmation.
  static const String purchasePending = 'monetization_purchase_pending';

  /// The purchase or its verification failed.
  static const String purchaseFailed = 'monetization_purchase_failed';

  /// The user dismissed the store purchase flow.
  static const String purchaseCanceled = 'monetization_purchase_canceled';

  /// A rewarded video was presented to the user.
  static const String rewardedAdShown = 'monetization_rewarded_ad_shown';

  /// A rewarded video was watched to the end.
  static const String rewardedAdCompleted = 'monetization_rewarded_ad_completed';

  /// A rewarded video was closed before the reward was earned.
  static const String rewardedAdSkipped = 'monetization_rewarded_ad_skipped';

  /// No rewarded video could be shown at all.
  static const String rewardedAdUnavailable = 'monetization_rewarded_ad_unavailable';

  /// A previously active subscription is no longer active.
  static const String subscriptionExpired = 'monetization_subscription_expired';
}
