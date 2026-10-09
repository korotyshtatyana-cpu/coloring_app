import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data.dart';

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
        .gt(RequestConstants.expiresAtColumn, DateTime.now().toIso8601String())
        .order(RequestConstants.expiresAtColumn, ascending: false)
        .limit(1);

    if (response.isEmpty) {
      return null;
    }
    return SubscriptionModel.fromJson(response.first);
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
    return response.first[RequestConstants.noAdsPurchasedColumn] as bool? ?? false;
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

  /// Inserts an entitlement row, replacing an existing one for the same
  /// `(user_id, contour_id)` pair.
  ///
  /// Watching a rewarded video twice, or buying after a rewarded unlock, must
  /// not create a duplicate row.
  Future<void> insertEntitlement(Map<String, dynamic> payload) async {
    await _client
        .from(RequestConstants.userEntitlementsTable)
        .upsert(payload, onConflict: RequestConstants.onConflictUserContourUpdate);
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
        .eq(RequestConstants.statusColumn, RequestConstants.pendingPurchaseStatusPending)
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
        .eq(RequestConstants.statusColumn, RequestConstants.pendingPurchaseStatusResolved)
        .order(RequestConstants.createdAtColumn, ascending: false);

    return response
        .map((Map<String, dynamic> json) => PendingPurchaseModel.fromJson(json))
        .toList();
  }
}
