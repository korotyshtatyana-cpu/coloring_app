import 'package:in_app_purchase/in_app_purchase.dart';

/// Abstraction over the platform billing SDK.
///
/// The application always talks to this interface, so the store-specific
/// details stay behind it and a new platform can be added without touching the
/// purchase flow. Android is currently the only implemented platform; see
/// [AppleBillingPlatform] for the iOS placeholder.
abstract class BillingPlatform {
  /// Prepares the store and re-delivers unfinished transactions, if any.
  Future<void> initialize();

  /// Stream of purchase updates reported by the store.
  Stream<List<PurchaseDetails>> get purchaseStream;

  /// Returns the store products matching [ids].
  Future<List<ProductDetails>> queryProducts(List<String> ids);

  /// Starts the store purchase flow for [productId].
  Future<void> purchase(String productId);

  /// Starts the store purchase flow for a subscription [productId] and one of
  /// its base plans.
  ///
  /// Google Play models the billing period as a base plan, so implementations
  /// resolve the matching offer token from the product details before launching
  /// the purchase. [currentProductId] and [currentBasePlanId] describe the
  /// subscription the user already owns, when known, so the store can replace
  /// it instead of creating a second subscription. Passing the same plan that
  /// is already active re-verifies the existing purchase.
  Future<void> purchaseSubscription({
    required String productId,
    required String basePlanId,
    String? currentProductId,
    String? currentBasePlanId,
  });

  /// Starts the store purchase flow for a consumable [productId].
  Future<void> purchaseConsumable(String productId);

  /// Restores previously purchased non-consumable products.
  Future<void> restorePurchases();

  /// Acknowledges a verified [purchase] so the store stops retrying it.
  Future<void> completePurchase(PurchaseDetails purchase);
}
