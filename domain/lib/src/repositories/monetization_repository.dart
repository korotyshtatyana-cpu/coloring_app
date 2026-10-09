import '../entities/pending_purchase_entity.dart';
import '../entities/subscription_entity.dart';
import '../entities/user_entitlement_entity.dart';

/// Repository for monetization and billing operations.
///
/// Implementations must resolve every value from the server. The app is
/// online-only, so no implementation may fall back to cached or locally stored
/// access state.
abstract class MonetizationRepository {
  /// Returns the user's currently active subscription, or `null` when the user
  /// has none.
  Future<SubscriptionEntity?> getActiveSubscription(String userId);

  /// Returns whether the user permanently owns the No Ads plan.
  Future<bool> isNoAdsPurchased(String userId);

  /// Returns the user's entitlement for a single project, or `null` when the
  /// user has none.
  Future<UserEntitlementEntity?> getEntitlement({
    required String userId,
    required String contourId,
  });

  /// Returns every entitlement granted to the user.
  Future<List<UserEntitlementEntity>> getAllEntitlements(String userId);

  /// Grants access to a project after a rewarded video was watched to the end.
  Future<void> grantRewardedUnlock({required String userId, required String contourId});

  /// Records an individually purchased project.
  Future<void> recordPurchase({
    required String userId,
    required String contourId,
    required String purchaseToken,
  });

  /// Queues a purchase that the store has not confirmed yet.
  Future<void> enqueuePendingPurchase({
    required String userId,
    required String productId,
    String? purchaseToken,
  });

  /// Returns the user's purchases still awaiting confirmation.
  Future<List<PendingPurchaseEntity>> getPendingPurchases(String userId);

  /// Returns the user's confirmed purchases, most recent first.
  Future<List<PendingPurchaseEntity>> getResolvedPurchases(String userId);
}
