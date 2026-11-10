import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data.dart';
import '../utils/server_time.dart';

/// Outcome of a server-side store verification.
enum PurchaseVerificationResult {
  /// The store confirmed the purchase and the entitlement was granted.
  verified,

  /// The store has not finalized the payment yet; verification must be retried.
  pending,

  /// The store rejected or canceled the payment.
  failed,
}

/// Remote provider for monetization data stored in Supabase.
///
/// The provider works with database records only: billing itself is driven by
/// the platform store from the Presentation layer. No method falls back to
/// cached values, so a network failure surfaces as an error instead of a
/// silently stale access decision.
class MonetizationRemoteProvider {
  final SupabaseClient _client;

  /// Creates a provider with the given [_client].
  MonetizationRemoteProvider({required this._client});

  /// Returns the identifier of the currently authenticated user, if any.
  String? get currentUserId => _client.auth.currentUser?.id;

  /// Verifies a store purchase with the `verify-purchase` Edge Function.
  ///
  /// The function derives the user from the JWT, validates the purchase with
  /// the platform store and grants the matching entitlement. Throws when the
  /// function rejects the purchase. Returns [PurchaseVerificationResult.pending]
  /// while the store is still finalizing the payment.
  Future<PurchaseVerificationResult> verifyPurchase({
    required String productId,
    required String purchaseToken,
    required String type,
    required String platform,
    String? contourId,
  }) async {
    final FunctionResponse response = await _client.functions.invoke(
      RequestConstants.verifyPurchaseFunction,
      body: <String, dynamic>{
        RequestConstants.productIdColumn: productId,
        RequestConstants.purchaseTokenColumn: purchaseToken,
        RequestConstants.typeColumn: type,
        RequestConstants.platformParam: platform,
        if (contourId != null) RequestConstants.contourIdColumn: contourId,
      },
    );

    if (response.status != 200) {
      throw StateError(
        response.data?.toString() ?? 'Purchase verification failed',
      );
    }

    final Object? data = response.data;
    if (data is Map<String, dynamic>) {
      final Object? status = data[RequestConstants.verificationStatusParam];
      if (status == RequestConstants.verificationStatusPending) {
        return PurchaseVerificationResult.pending;
      }
      if (status == RequestConstants.verificationStatusFailed) {
        return PurchaseVerificationResult.failed;
      }
    }
    return PurchaseVerificationResult.verified;
  }

  /// Returns the user's active, unexpired subscription, or `null`.
  ///
  /// When several rows qualify, the one expiring last is returned so the user
  /// keeps the widest access.
  Future<SubscriptionModel?> getActiveSubscription(String userId) async {
    final List<Map<String, dynamic>> response = await _client
        .from(RequestConstants.subscriptionsTable)
        .select(RequestConstants.selectAll)
        .eq(RequestConstants.userIdColumn, userId)
        .eq(RequestConstants.isActiveColumn, true)
        .gt(RequestConstants.expiresAtColumn, serverNowIso8601())
        // A plan change can briefly leave the replaced subscription active in
        // the table until its store notification arrives. The newest purchase
        // is the plan the user currently owns, even when the old one has a
        // later expiry (for example an annual No Ads replaced by a monthly
        // Premium).
        .order(RequestConstants.startedAtColumn, ascending: false)
        .order(RequestConstants.expiresAtColumn, ascending: false)
        .limit(1);

    if (response.isEmpty) {
      return null;
    }
    return SubscriptionModel.fromJson(response.first);
  }

  /// Returns every subscription owned by the user, newest first.
  Future<List<SubscriptionModel>> getSubscriptions(String userId) async {
    final List<Map<String, dynamic>> response = await _client
        .from(RequestConstants.subscriptionsTable)
        .select(RequestConstants.selectAll)
        .eq(RequestConstants.userIdColumn, userId)
        .order(RequestConstants.startedAtColumn, ascending: false);

    return response
        .map((Map<String, dynamic> json) => SubscriptionModel.fromJson(json))
        .toList();
  }

  /// Returns every paid subscription period, newest first.
  ///
  /// Each row is an initial purchase or an automatic renewal. The history
  /// screen uses the billing period and the auto-renewal flag from these rows.
  Future<List<SubscriptionPurchaseModel>> getSubscriptionPurchases(
    String userId,
  ) async {
    final List<Map<String, dynamic>> response = await _client
        .from(RequestConstants.subscriptionPurchasesTable)
        .select(RequestConstants.selectAll)
        .eq(RequestConstants.userIdColumn, userId)
        .order(RequestConstants.startedAtColumn, ascending: false);

    return response
        .map(
          (Map<String, dynamic> json) =>
              SubscriptionPurchaseModel.fromJson(json),
        )
        .toList();
  }

  /// Returns the `no_ads_purchased` flag from the `users` table.
  Future<bool> getNoAdsFlag(String userId) async {
    final List<Map<String, dynamic>> response = await _client
        .from(RequestConstants.usersTable)
        .select(RequestConstants.selectNoAdsPurchased)
        .eq(RequestConstants.idColumn, userId)
        .limit(1);

    if (response.isEmpty) {
      return false;
    }
    return response.first[RequestConstants.noAdsPurchasedColumn] as bool? ??
        false;
  }

  /// Returns the user's entitlement for a single contour, or `null`.
  Future<UserEntitlementModel?> getEntitlement({
    required String userId,
    required String contourId,
  }) async {
    final List<Map<String, dynamic>> response = await _client
        .from(RequestConstants.userEntitlementsTable)
        .select(RequestConstants.selectAll)
        .eq(RequestConstants.userIdColumn, userId)
        .eq(RequestConstants.contourIdColumn, contourId)
        .limit(1);

    if (response.isEmpty) {
      return null;
    }
    return UserEntitlementModel.fromJson(response.first);
  }

  /// Returns every entitlement granted to the user.
  Future<List<UserEntitlementModel>> getAllEntitlements(String userId) async {
    final List<Map<String, dynamic>> response = await _client
        .from(RequestConstants.userEntitlementsTable)
        .select(RequestConstants.selectAll)
        .eq(RequestConstants.userIdColumn, userId);

    return response
        .map((Map<String, dynamic> json) => UserEntitlementModel.fromJson(json))
        .toList();
  }

  /// Returns the user's individually purchased projects, newest first.
  ///
  /// Each row includes the contour title and preview URL so the purchase
  /// history can show what was bought without a second request. Rewarded and
  /// subscription entitlements are excluded: only `purchase` rows represent a
  /// one-time project purchase.
  Future<List<UserEntitlementModel>> getPurchasedEntitlements(
    String userId,
  ) async {
    final List<Map<String, dynamic>> response = await _client
        .from(RequestConstants.userEntitlementsTable)
        .select(RequestConstants.selectPurchasedEntitlements)
        .eq(RequestConstants.userIdColumn, userId)
        .eq(
          RequestConstants.typeColumn,
          RequestConstants.entitlementTypePurchase,
        )
        .order(RequestConstants.grantedAtColumn, ascending: false);

    return response
        .map((Map<String, dynamic> json) => UserEntitlementModel.fromJson(json))
        .toList();
  }

  /// Inserts an entitlement row, replacing an existing one for the same
  /// `(user_id, contour_id)` pair.
  ///
  /// Watching a rewarded video twice, or buying after a rewarded unlock, must
  /// not create a duplicate row.
  Future<void> insertEntitlement(Map<String, dynamic> payload) async {
    await _client
        .from(RequestConstants.userEntitlementsTable)
        .upsert(
          payload,
          onConflict: RequestConstants.onConflictUserContourUpdate,
        );
  }

  /// Inserts a queued purchase awaiting store confirmation.
  Future<void> insertPendingPurchase(Map<String, dynamic> payload) async {
    await _client.from(RequestConstants.pendingPurchasesTable).insert(payload);
  }

  /// Returns the user's purchases still awaiting confirmation, oldest first.
  Future<List<PendingPurchaseModel>> getPendingPurchases(String userId) async {
    final List<Map<String, dynamic>> response = await _client
        .from(RequestConstants.pendingPurchasesTable)
        .select(RequestConstants.selectAll)
        .eq(RequestConstants.userIdColumn, userId)
        .eq(
          RequestConstants.statusColumn,
          RequestConstants.pendingPurchaseStatusPending,
        )
        .order(RequestConstants.createdAtColumn, ascending: true);

    return response
        .map((Map<String, dynamic> json) => PendingPurchaseModel.fromJson(json))
        .toList();
  }

  /// Returns the user's confirmed purchases, most recent first.
  Future<List<PendingPurchaseModel>> getResolvedPurchases(String userId) async {
    final List<Map<String, dynamic>> response = await _client
        .from(RequestConstants.pendingPurchasesTable)
        .select(RequestConstants.selectAll)
        .eq(RequestConstants.userIdColumn, userId)
        .eq(
          RequestConstants.statusColumn,
          RequestConstants.pendingPurchaseStatusResolved,
        )
        .order(RequestConstants.createdAtColumn, ascending: false);

    return response
        .map((Map<String, dynamic> json) => PendingPurchaseModel.fromJson(json))
        .toList();
  }

  /// Returns refunds the user has not seen yet, most recent first.
  Future<List<PurchaseRefundModel>> getUnacknowledgedRefunds(
    String userId,
  ) async {
    final List<Map<String, dynamic>> response = await _client
        .from(RequestConstants.purchaseRefundsTable)
        .select(RequestConstants.selectAll)
        .eq(RequestConstants.userIdColumn, userId)
        .isFilter(RequestConstants.acknowledgedAtColumn, null)
        .order(RequestConstants.createdAtColumn, ascending: false);

    return response
        .map((Map<String, dynamic> json) => PurchaseRefundModel.fromJson(json))
        .toList();
  }

  /// Marks a refund message as seen by the user.
  Future<void> acknowledgeRefund(String refundId) async {
    await _client
        .from(RequestConstants.purchaseRefundsTable)
        .update(<String, dynamic>{
          RequestConstants.acknowledgedAtColumn: serverNowIso8601(),
        })
        .eq(RequestConstants.idColumn, refundId);
  }
}
