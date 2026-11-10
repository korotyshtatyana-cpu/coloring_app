import 'dart:io';

import 'package:core/core.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../constants/request_constants.dart';
import 'billing_platform.dart';

/// A subscription offer resolved from Google Play product details.
typedef _SubscriptionOffer = ({
  GooglePlayProductDetails details,
  String offerToken,
  bool isRegularBasePlan,
});

/// Google Play Billing implementation of [BillingPlatform].
///
/// Wraps the `in_app_purchase` plugin and is the only class that talks to the
/// store SDK directly. Server-side verification is handled by the repository,
/// not here.
class GooglePlayBillingPlatform implements BillingPlatform {
  final InAppPurchase _store;

  /// Resolved offers keyed by `productId/basePlanId`.
  final Map<String, _SubscriptionOffer> _subscriptionOffers =
      <String, _SubscriptionOffer>{};

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
    final ProductDetailsResponse response = await _store.queryProductDetails(
      ids.toSet(),
    );
    if (response.error != null) {
      appLocator<AppLogger>().warning(
        'Google Play product query failed: ${response.error}',
      );
    }
    if (response.notFoundIDs.isNotEmpty) {
      appLocator<AppLogger>().warning(
        'Google Play products not found: ${response.notFoundIDs.join(', ')}',
      );
    }
    _cacheSubscriptionOffers(response.productDetails);
    return response.productDetails;
  }

  @override
  Future<void> purchase(String productId) async {
    final List<ProductDetails> products = await queryProducts(<String>[
      productId,
    ]);
    if (products.isEmpty) {
      throw StateError('Product $productId is not available in the store');
    }
    await _store.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: products.first),
    );
  }

  @override
  Future<void> purchaseSubscription({
    required String productId,
    required String basePlanId,
    String? currentProductId,
    String? currentBasePlanId,
  }) async {
    final String key = _subscriptionKey(productId, basePlanId);
    final _SubscriptionOffer? offer =
        _subscriptionOffers[key] ??
        await _resolveSubscriptionOffer(productId, basePlanId);
    if (offer == null) {
      throw StateError(
        'Base plan $basePlanId for product $productId is not available '
        'in the store',
      );
    }

    final GooglePlayPurchaseDetails? existing = await _activeSubscription(
      preferredProductId: currentProductId,
    );
    final String? existingBasePlanId =
        existing?.productID == currentProductId ? currentBasePlanId : null;
    // Asking Google Play to replace a subscription with itself is rejected.
    // Re-verify the owned purchase instead so the user keeps the same plan and
    // the transaction gets acknowledged.
    final bool isSamePlan =
        existing != null &&
        existing.productID == productId &&
        (existingBasePlanId == null || existingBasePlanId == basePlanId);
    if (isSamePlan) {
      await _store.restorePurchases();
      return;
    }

    // Runtime replacement modes are only accepted when switching between
    // different subscription products. A base-plan change inside one product
    // uses the mode configured for that subscription in Play Console.
    final bool switchesProduct =
        existing != null && existing.productID != productId;
    await _store.buyNonConsumable(
      purchaseParam: GooglePlayPurchaseParam(
        productDetails: offer.details,
        offerToken: offer.offerToken,
        changeSubscriptionParam: existing == null
            ? null
            : ChangeSubscriptionParam(
                oldPurchaseDetails: existing,
                replacementMode: switchesProduct
                    // Switch immediately and credit the unused time of the old
                    // plan toward the new one.
                    ? ReplacementMode.withTimeProration
                    : null,
              ),
      ),
    );
  }

  @override
  Future<void> purchaseConsumable(String productId) async {
    final List<ProductDetails> products = await queryProducts(<String>[
      productId,
    ]);
    if (products.isEmpty) {
      throw StateError('Product $productId is not available in the store');
    }
    await _store.buyConsumable(
      purchaseParam: PurchaseParam(productDetails: products.first),
      autoConsume: false,
    );
  }

  @override
  Future<void> restorePurchases() => _store.restorePurchases();

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    if (purchase.productID == RequestConstants.creditProductId &&
        purchase.status != PurchaseStatus.error &&
        Platform.isAndroid) {
      final InAppPurchaseAndroidPlatformAddition addition = _store
          .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      final BillingResultWrapper result = await addition.consumePurchase(
        purchase,
      );
      if (result.responseCode != BillingResponse.ok) {
        throw StateError(
          'Failed to consume credit purchase: ${result.debugMessage}',
        );
      }
      return;
    }
    return _store.completePurchase(purchase);
  }

  /// Returns the subscription the user already owns, if any.
  ///
  /// Google Play only allows a second subscription purchase when the existing
  /// one is passed to the store as the purchase being replaced. The current
  /// purchases query is the authoritative source for that old transaction.
  Future<GooglePlayPurchaseDetails?> _activeSubscription({
    String? preferredProductId,
  }) async {
    if (!Platform.isAndroid) {
      return null;
    }
    try {
      final InAppPurchaseAndroidPlatformAddition addition = _store
          .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      final QueryPurchaseDetailsResponse response = await addition
          .queryPastPurchases();
      if (response.error != null) {
        appLocator<AppLogger>().warning(
          'Google Play past purchase query failed: ${response.error!.message}',
        );
      }
      final List<GooglePlayPurchaseDetails> subscriptions = response
          .pastPurchases
          .where(
            (GooglePlayPurchaseDetails purchase) =>
                RequestConstants.isSubscriptionProduct(purchase.productID) &&
                (purchase.status == PurchaseStatus.purchased ||
                    purchase.status == PurchaseStatus.restored),
          )
          .toList();
      if (subscriptions.isEmpty) {
        return null;
      }
      if (preferredProductId != null) {
        for (final GooglePlayPurchaseDetails purchase in subscriptions) {
          if (purchase.productID == preferredProductId) {
            return purchase;
          }
        }
      }
      return subscriptions.first;
    } catch (error) {
      // A failed lookup must not block the purchase flow. Falling back to a
      // normal purchase keeps the previous behaviour and the store reports a
      // clear error if it cannot replace the active subscription.
      appLocator<AppLogger>().warning(
        'Google Play past purchase query failed: $error',
      );
      return null;
    }
  }

  Future<_SubscriptionOffer?> _resolveSubscriptionOffer(
    String productId,
    String basePlanId,
  ) async {
    // queryProducts populates the cache from subscriptionOfferDetails.
    await queryProducts(<String>[productId]);
    return _subscriptionOffers[_subscriptionKey(productId, basePlanId)];
  }

  void _cacheSubscriptionOffers(List<ProductDetails> products) {
    for (final ProductDetails product in products) {
      if (product is! GooglePlayProductDetails) {
        continue;
      }
      final int? subscriptionIndex = product.subscriptionIndex;
      final List<SubscriptionOfferDetailsWrapper>? offers =
          product.productDetails.subscriptionOfferDetails;
      if (subscriptionIndex == null ||
          offers == null ||
          subscriptionIndex >= offers.length) {
        continue;
      }
      final SubscriptionOfferDetailsWrapper offer = offers[subscriptionIndex];
      final String? offerToken = product.offerToken;
      if (offerToken == null || offerToken.isEmpty) {
        continue;
      }

      final String key = _subscriptionKey(product.id, offer.basePlanId);
      final bool isRegularBasePlan = offer.offerId == null;
      // Prefer the regular base plan over a discounted introductory offer.
      if (_subscriptionOffers[key]?.isRegularBasePlan == true &&
          !isRegularBasePlan) {
        continue;
      }
      _subscriptionOffers[key] = (
        details: product,
        offerToken: offerToken,
        isRegularBasePlan: isRegularBasePlan,
      );
    }
  }

  String _subscriptionKey(String productId, String basePlanId) {
    return '$productId/$basePlanId';
  }
}
