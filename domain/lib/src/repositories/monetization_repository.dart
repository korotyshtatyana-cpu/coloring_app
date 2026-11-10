import '../entities/billing_product_entity.dart';
import '../entities/pending_purchase_entity.dart';
import '../entities/purchase_refund_entity.dart';
import '../entities/purchase_update_entity.dart';
import '../entities/subscription_entity.dart';
import '../entities/subscription_interval.dart';
import '../entities/subscription_plan_type.dart';
import '../entities/subscription_price_entity.dart';
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
  Future<void> grantRewardedUnlock({
    required String userId,
    required String contourId,
  });

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
    String? contourId,
  });

  /// Returns the user's purchases still awaiting confirmation.
  Future<List<PendingPurchaseEntity>> getPendingPurchases(String userId);

  /// Re-checks a queued [purchase] with the store.
  ///
  /// Returns [PendingPurchaseRefreshStatus.verified] once the store confirmed
  /// the payment and the entitlement is available. Throws when the store
  /// rejects the purchase.
  Future<PendingPurchaseRefreshStatus> refreshPendingPurchase(
    PendingPurchaseEntity purchase,
  );

  /// Returns the user's confirmed purchases, most recent first.
  Future<List<PendingPurchaseEntity>> getResolvedPurchases(String userId);

  /// Returns refunds the user has not seen yet, most recent first.
  Future<List<PurchaseRefundEntity>> getUnacknowledgedRefunds(String userId);

  /// Marks a refund notification as seen by the user.
  Future<void> acknowledgeRefund(String refundId);

  /// Stream of refunds reported for the user in real time.
  ///
  /// Events arrive as soon as the server records a refund; refunds discovered
  /// through [getUnacknowledgedRefunds] (the fallback path) are emitted here
  /// too, so every listener sees the same deduplicated sequence.
  Stream<PurchaseRefundEntity> watchRefunds(String userId);

  /// Stream of purchase and restore outcomes reported by the platform store.
  Stream<PurchaseUpdateEntity> get purchaseUpdates;

  /// Returns the store products available for purchase.
  Future<List<BillingProductEntity>> getBillingProducts();

  /// Returns localized store prices for every subscription base plan.
  ///
  /// Products whose price cannot be resolved are omitted.
  Future<List<SubscriptionPriceEntity>> getSubscriptionPrices();

  /// Returns the one-time credit product, or `null` when the store does not
  /// offer it.
  Future<BillingProductEntity?> getCreditProduct();

  /// Starts the store purchase flow for a subscription [plan] and [interval].
  ///
  /// [currentProductId] and [currentBasePlanId] describe the subscription the
  /// user already owns, so the store can replace it instead of creating a
  /// second subscription.
  Future<void> buySubscription({
    required SubscriptionPlanType plan,
    required SubscriptionInterval interval,
    String? currentProductId,
    String? currentBasePlanId,
  });

  /// Starts the store purchase flow for a single project.
  ///
  /// When [productId] is `null` the data layer falls back to the project's
  /// `contour_{contourId}` identifier.
  Future<void> buyProject({required String contourId, String? productId});

  /// Starts the one-time credit purchase used to unlock [contourId].
  ///
  /// The purchased credit is spent on the contour as soon as the store
  /// confirms the transaction.
  Future<void> buyCredit({required String contourId});

  /// Restores previously purchased subscriptions and projects.
  ///
  /// Restored purchases are verified and reported through [purchaseUpdates].
  Future<void> restorePurchases();
}
