import 'package:domain/domain.dart';

/// Constants used for remote data requests and table names.
abstract final class RequestConstants {
  // Supabase schema
  static const String publicSchema = 'public';

  // Supabase table names
  static const String usersTable = 'users';
  static const String contoursTable = 'contours';
  static const String favoritesTable = 'favorites';
  static const String projectsTable = 'projects';
  static const String feedbackTable = 'feedback';
  static const String subscriptionsTable = 'subscriptions';
  static const String subscriptionPurchasesTable = 'subscription_purchases';
  static const String userEntitlementsTable = 'user_entitlements';
  static const String pendingPurchasesTable = 'pending_purchases';
  static const String purchaseRefundsTable = 'purchase_refunds';

  // Supabase Edge Functions
  static const String verifyPurchaseFunction = 'verify-purchase';
  static const String googlePlayWebhookFunction = 'google-play-webhook';

  // Supabase Storage buckets
  static const String thumbnailsBucket = 'project_thumbnails';
  static const String feedbackBucket = 'feedback_attachments';

  // Supabase Storage file naming
  static const String thumbnailFileExtension = '.png';
  static const String pngMimeType = 'image/png';

  // Supabase query columns
  static const String selectAll = '*';
  static const String selectContourCategories = 'categories, category';
  static const String selectContourId = 'contour_id';
  static const String selectProjectData = 'contour_id, data, last_opened';
  static const String selectProjectThumbnails =
      'contour_id, thumbnail_url, last_opened';

  // Supabase columns
  static const String createdAtColumn = 'created_at';
  static const String categoryColumn = 'category';
  static const String categoriesColumn = 'categories';
  static const String userIdColumn = 'user_id';
  static const String subscriptionIdColumn = 'subscription_id';
  static const String contourIdColumn = 'contour_id';
  static const String lastOpenedColumn = 'last_opened';
  static const String dataColumn = 'data';
  static const String thumbnailUrlColumn = 'thumbnail_url';
  static const String updatedAtColumn = 'updated_at';
  static const String planTypeColumn = 'plan_type';
  static const String basePlanIdColumn = 'base_plan_id';
  static const String isActiveColumn = 'is_active';
  static const String startedAtColumn = 'started_at';
  static const String expiresAtColumn = 'expires_at';
  static const String purchaseTokenColumn = 'purchase_token';
  static const String orderIdColumn = 'order_id';
  static const String isAutoRenewalColumn = 'is_auto_renewal';
  static const String isAutoRenewColumn = 'is_auto_renew';
  static const String grantedAtColumn = 'granted_at';
  static const String productIdColumn = 'product_id';
  static const String statusColumn = 'status';
  static const String errorMessageColumn = 'error_message';
  static const String resolvedAtColumn = 'resolved_at';
  static const String acknowledgedAtColumn = 'acknowledged_at';
  static const String typeColumn = 'type';
  static const String idColumn = 'id';
  static const String noAdsPurchasedColumn = 'no_ads_purchased';
  static const String accessTypeColumn = 'access_type';
  static const String priceColumn = 'price';
  static const String titleColumn = 'title';
  static const String previewUrlColumn = 'preview_url';

  // Supabase query parameters
  static const String limitParam = 'limit';
  static const String offsetParam = 'offset';
  static const String orderParam = 'order';
  static const String categoryParam = 'category';
  static const String userIdParam = 'user_id';
  static const String contourIdParam = 'contour_id';
  static const String platformParam = 'platform';
  static const String onConflictUserContour = 'user_id,contour_id';
  static const String onConflictUserContourUpdate = 'user_id,contour_id';

  // Monetization column selections
  static const String selectNoAdsPurchased = 'no_ads_purchased';

  /// Entitlement row together with the contour it unlocks.
  ///
  /// The embedded `contours` object supplies the title and preview image shown
  /// in the purchase history.
  static const String selectPurchasedEntitlements =
      '*, contours(title, preview_url)';

  // Monetization enum values stored in the database
  static const String planTypeNoAds = 'no_ads';
  static const String planTypePremium = 'premium';

  static const String entitlementTypePurchase = 'purchase';
  static const String entitlementTypeRewardedUnlock = 'rewarded_unlock';
  static const String entitlementTypeSubscriptionAccess = 'subscription_access';

  static const String pendingPurchaseStatusPending = 'pending';
  static const String pendingPurchaseStatusResolved = 'resolved';
  static const String pendingPurchaseStatusFailed = 'failed';

  // Monetization defaults
  static const String defaultContourAccessType = 'free';

  // Google Play Billing product identifiers.
  //
  // Google Play's modern subscription model uses one product per plan with
  // multiple base plans. The billing period (week/month/year) is the base plan
  // id and is resolved at runtime from `subscriptionOfferDetails`.
  static const String noAdsProductId = 'no_ads';
  static const String premiumProductId = 'premium';

  /// Every subscription product offered by the app.
  static const List<String> subscriptionProductIds = <String>[
    noAdsProductId,
    premiumProductId,
  ];

  /// Prefix of the fallback product identifier of a paid project.
  static const String contourProductIdPrefix = 'contour_';

  /// One-time product that adds a single contour-unlock credit.
  static const String creditProductId = 'unlock_credit';

  // Billing verification payload values
  static const String purchaseTypeSubscription = 'subscription';
  static const String purchaseTypeCredits = 'credits';
  static const String purchaseTypeProduct = 'product';
  static const String platformGoogle = 'google';
  static const String platformApple = 'apple';

  // Billing verification response values
  static const String verificationStatusParam = 'status';
  static const String verificationStatusPending = 'pending';
  static const String verificationStatusVerified = 'verified';
  static const String verificationStatusFailed = 'failed';

  // Billing recovery timings
  static const Duration restoreResultTimeout = Duration(seconds: 4);

  /// How long a cached subscription or No Ads flag stays usable.
  ///
  /// The cache only avoids repeat queries when the gallery re-opens; access
  /// decisions still evaluate the subscription's own expiry time, so a stale
  /// entry can never grant access to an expired plan.
  static const Duration monetizationCacheTtl = Duration(minutes: 5);

  /// Resolves the store product id and base plan id for [plan] and [interval].
  ///
  /// Google Play exposes one subscription product per plan; the billing period
  /// is a base plan inside that product.
  static ({String productId, String basePlanId}) subscriptionProduct(
    SubscriptionPlanType plan,
    SubscriptionInterval interval,
  ) {
    return (productId: plan.dbValue, basePlanId: interval.dbValue);
  }

  /// Returns whether [productId] is one of the subscription products.
  static bool isSubscriptionProduct(String productId) {
    return subscriptionProductIds.contains(productId);
  }

  // RPC functions and parameters
  static const String toggleFavoriteRpc = 'toggle_favorite';
  static const String pUserId = 'p_user_id';
  static const String pContourId = 'p_contour_id';

  // Error messages
  static const String userNotAuthenticated = 'User not authenticated';
  static const String googleSignInAborted = 'Google sign in aborted';
  static const String googleIdTokenNull = 'Google idToken is null';
  static const String googleSignInFailed = 'Failed to sign in with Google';
  static const String appleIdTokenNull = 'Apple idToken is null';
  static const String appleSignInFailed = 'Failed to sign in with Apple';
  static const String platformNotSupported = 'Platform is not supported';
  static const String silentSignInNotAvailable =
      'Silent sign-in is not available';

  // Postgres error codes
  static const String codeUniqueViolation = '23505';

  // Export file name
  static const String exportFilePrefix = 'coloring_pro';
}
