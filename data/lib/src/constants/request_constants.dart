import 'package:domain/domain.dart';

/// Constants used for remote data requests and table names.
abstract final class RequestConstants {
  // Supabase table names
  static const String usersTable = 'users';
  static const String contoursTable = 'contours';
  static const String favoritesTable = 'favorites';
  static const String projectsTable = 'projects';
  static const String feedbackTable = 'feedback';
  static const String subscriptionsTable = 'subscriptions';
  static const String userEntitlementsTable = 'user_entitlements';
  static const String pendingPurchasesTable = 'pending_purchases';

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
  static const String selectContourId = 'contour_id';
  static const String selectProjectData = 'contour_id, data, last_opened';
  static const String selectProjectThumbnails = 'contour_id, thumbnail_url, last_opened';

  // Supabase columns
  static const String createdAtColumn = 'created_at';
  static const String categoryColumn = 'category';
  static const String userIdColumn = 'user_id';
  static const String contourIdColumn = 'contour_id';
  static const String lastOpenedColumn = 'last_opened';
  static const String dataColumn = 'data';
  static const String thumbnailUrlColumn = 'thumbnail_url';
  static const String updatedAtColumn = 'updated_at';
  static const String planTypeColumn = 'plan_type';
  static const String isActiveColumn = 'is_active';
  static const String startedAtColumn = 'started_at';
  static const String expiresAtColumn = 'expires_at';
  static const String purchaseTokenColumn = 'purchase_token';
  static const String grantedAtColumn = 'granted_at';
  static const String productIdColumn = 'product_id';
  static const String statusColumn = 'status';
  static const String errorMessageColumn = 'error_message';
  static const String resolvedAtColumn = 'resolved_at';
  static const String typeColumn = 'type';
  static const String idColumn = 'id';
  static const String noAdsPurchasedColumn = 'no_ads_purchased';
  static const String accessTypeColumn = 'access_type';
  static const String priceColumn = 'price';

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

  // Google Play Billing product identifiers
  static const String noAdsWeekProductId = 'no_ads_week';
  static const String noAdsMonthProductId = 'no_ads_month';
  static const String noAdsYearProductId = 'no_ads_year';
  static const String premiumWeekProductId = 'premium_week';
  static const String premiumMonthProductId = 'premium_month';
  static const String premiumYearProductId = 'premium_year';

  /// Every subscription product offered by the app.
  static const List<String> subscriptionProductIds = <String>[
    noAdsWeekProductId,
    noAdsMonthProductId,
    noAdsYearProductId,
    premiumWeekProductId,
    premiumMonthProductId,
    premiumYearProductId,
  ];

  /// Prefix of the fallback product identifier of a paid project.
  static const String contourProductIdPrefix = 'contour_';

  // Billing verification payload values
  static const String purchaseTypeSubscription = 'subscription';
  static const String purchaseTypeProduct = 'product';
  static const String platformGoogle = 'google';
  static const String platformApple = 'apple';

  // Billing recovery timings
  static const Duration restoreResultTimeout = Duration(seconds: 4);

  /// Returns the store product identifier for a [plan] and [interval].
  static String subscriptionProductId(
    SubscriptionPlanType plan,
    SubscriptionInterval interval,
  ) {
    return '${plan.dbValue}_${interval.dbValue}';
  }

  /// Returns whether [productId] is one of the subscription SKUs.
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
  static const String silentSignInNotAvailable = 'Silent sign-in is not available';

  // Postgres error codes
  static const String codeUniqueViolation = '23505';

  // Export file name
  static const String exportFilePrefix = 'coloring_pro';
}
