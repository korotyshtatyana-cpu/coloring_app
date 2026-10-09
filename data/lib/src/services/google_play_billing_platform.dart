import 'package:core/core.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'billing_platform.dart';

/// Google Play Billing implementation of [BillingPlatform].
///
/// Wraps the `in_app_purchase` plugin and is the only class that talks to the
/// store SDK directly. Server-side verification is handled by the repository,
/// not here.
class GooglePlayBillingPlatform implements BillingPlatform {
  final InAppPurchase _store;

  /// Creates a [GooglePlayBillingPlatform].
  ///
  /// The [store] is injectable for tests and defaults to the platform store
  /// singleton.
  GooglePlayBillingPlatform({InAppPurchase? store})
      : _store = store ?? InAppPurchase.instance;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _store.purchaseStream;

  @override
  Future<void> initialize() async {
    if (!await _store.isAvailable()) {
      appLocator<AppLogger>().warning('Google Play Billing is not available');
      return;
    }
    // Re-deliver transactions that were not finished in a previous session.
    await _store.restorePurchases();
  }

  @override
  Future<List<ProductDetails>> queryProducts(List<String> ids) async {
    if (ids.isEmpty) {
      return const <ProductDetails>[];
    }
    final ProductDetailsResponse response = await _store.queryProductDetails(ids.toSet());
    return response.productDetails;
  }

  @override
  Future<void> purchase(String productId) async {
    final List<ProductDetails> products = await queryProducts(<String>[productId]);
    if (products.isEmpty) {
      throw StateError('Product $productId is not available in the store');
    }
    await _store.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: products.first),
    );
  }

  @override
  Future<void> restorePurchases() => _store.restorePurchases();

  @override
  Future<void> completePurchase(PurchaseDetails purchase) {
    return _store.completePurchase(purchase);
  }
}
