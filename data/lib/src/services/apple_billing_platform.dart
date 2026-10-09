import 'package:in_app_purchase/in_app_purchase.dart';

import 'billing_platform.dart';

/// iOS placeholder for [BillingPlatform].
///
/// TODO: When releasing to iOS, implement via `in_app_purchase` for the App
/// Store and configure App Store Connect SKUs. See MONETIZATION.md
/// ("Future: iOS Billing") for the full checklist.
///
/// Do NOT add iOS-specific imports or StoreKit configuration now.
class AppleBillingPlatform implements BillingPlatform {
  @override
  Future<void> initialize() {
    throw UnimplementedError('Apple billing not implemented yet');
  }

  @override
  Stream<List<PurchaseDetails>> get purchaseStream {
    throw UnimplementedError('Apple billing not implemented yet');
  }

  @override
  Future<List<ProductDetails>> queryProducts(List<String> ids) {
    throw UnimplementedError('Apple billing not implemented yet');
  }

  @override
  Future<void> purchase(String productId) {
    throw UnimplementedError('Apple billing not implemented yet');
  }

  @override
  Future<void> restorePurchases() {
    throw UnimplementedError('Apple billing not implemented yet');
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) {
    throw UnimplementedError('Apple billing not implemented yet');
  }
}
