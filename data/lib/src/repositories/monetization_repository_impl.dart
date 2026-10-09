import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:domain/domain.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../data.dart';

/// Implementation of [MonetizationRepository] using
/// [MonetizationRemoteProvider] and [BillingPlatform].
///
/// Every value is resolved from the server on each call: the app has no
/// offline mode, so nothing here caches access decisions or falls back to a
/// previous subscription state.
///
/// Confirmed store transactions are verified on the server before the
/// entitlement is granted. Failures are queued in `pending_purchases` and
/// resolved on a later check.
class MonetizationRepositoryImpl implements MonetizationRepository {
  final MonetizationRemoteProvider _remoteProvider;
  final BillingPlatform _billingPlatform;
  final StreamController<PurchaseUpdateEntity> _updates =
      StreamController<PurchaseUpdateEntity>.broadcast();

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  Timer? _restoreTimer;
  int _restoredCount = 0;

  /// Creates a repository with the given [_remoteProvider] and
  /// [_billingPlatform].
  MonetizationRepositoryImpl({
    required this._remoteProvider,
    required this._billingPlatform,
  }) {
    _purchaseSubscription = _billingPlatform.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (Object error, StackTrace stackTrace) {
        ErrorHandler.report(error, stackTrace);
      },
    );
  }

  @override
  Future<SubscriptionEntity?> getActiveSubscription(String userId) async {
    final SubscriptionModel? model = await _remoteProvider.getActiveSubscription(userId);
    return model == null ? null : SubscriptionMapper.toEntity(model);
  }

  @override
  Future<bool> isNoAdsPurchased(String userId) {
    return _remoteProvider.getNoAdsFlag(userId);
  }

  @override
  Future<UserEntitlementEntity?> getEntitlement({
    required String userId,
    required String contourId,
  }) async {
    final UserEntitlementModel? model = await _remoteProvider.getEntitlement(
      userId: userId,
      contourId: contourId,
    );
    return model == null ? null : UserEntitlementMapper.toEntity(model);
  }

  @override
  Future<List<UserEntitlementEntity>> getAllEntitlements(String userId) async {
    final List<UserEntitlementModel> models = await _remoteProvider.getAllEntitlements(userId);

    return models.map(UserEntitlementMapper.toEntity).whereType<UserEntitlementEntity>().toList();
  }

  @override
  Future<void> grantRewardedUnlock({required String userId, required String contourId}) {
    return _remoteProvider.insertEntitlement(<String, dynamic>{
      RequestConstants.userIdColumn: userId,
      RequestConstants.contourIdColumn: contourId,
      RequestConstants.typeColumn: RequestConstants.entitlementTypeRewardedUnlock,
      RequestConstants.grantedAtColumn: DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> recordPurchase({
    required String userId,
    required String contourId,
    required String purchaseToken,
  }) {
    return _remoteProvider.insertEntitlement(<String, dynamic>{
      RequestConstants.userIdColumn: userId,
      RequestConstants.contourIdColumn: contourId,
      RequestConstants.typeColumn: RequestConstants.entitlementTypePurchase,
      RequestConstants.grantedAtColumn: DateTime.now().toIso8601String(),
      // An individual purchase never expires.
      RequestConstants.expiresAtColumn: null,
      RequestConstants.purchaseTokenColumn: purchaseToken,
    });
  }

  @override
  Future<void> enqueuePendingPurchase({
    required String userId,
    required String productId,
    String? purchaseToken,
  }) {
    return _remoteProvider.insertPendingPurchase(<String, dynamic>{
      RequestConstants.userIdColumn: userId,
      RequestConstants.productIdColumn: productId,
      RequestConstants.purchaseTokenColumn: purchaseToken,
      RequestConstants.statusColumn: RequestConstants.pendingPurchaseStatusPending,
    });
  }

  @override
  Future<List<PendingPurchaseEntity>> getPendingPurchases(String userId) async {
    final List<PendingPurchaseModel> models = await _remoteProvider.getPendingPurchases(userId);
    return models.map(PendingPurchaseMapper.toEntity).toList();
  }

  @override
  Future<List<PendingPurchaseEntity>> getResolvedPurchases(String userId) async {
    final List<PendingPurchaseModel> models = await _remoteProvider.getResolvedPurchases(userId);
    return models.map(PendingPurchaseMapper.toEntity).toList();
  }

  @override
  Stream<PurchaseUpdateEntity> get purchaseUpdates => _updates.stream;

  @override
  Future<List<BillingProductEntity>> getBillingProducts() async {
    final List<ProductDetails> products = await _billingPlatform.queryProducts(
      RequestConstants.subscriptionProductIds,
    );
    return products.map(_toProductEntity).toList();
  }

  @override
  Future<void> buySubscription({
    required SubscriptionPlanType plan,
    required SubscriptionInterval interval,
  }) {
    return _billingPlatform.purchase(
      RequestConstants.subscriptionProductId(plan, interval),
    );
  }

  @override
  Future<void> buyProject({required String contourId, String? productId}) {
    return _billingPlatform.purchase(
      productId ?? '${RequestConstants.contourProductIdPrefix}$contourId',
    );
  }

  @override
  Future<void> restorePurchases() async {
    _restoredCount = 0;
    _restoreTimer?.cancel();
    _restoreTimer = Timer(RequestConstants.restoreResultTimeout, () {
      if (_restoredCount == 0) {
        _emit(
          const PurchaseUpdateEntity(
            status: PurchaseUpdateStatus.empty,
            isRestore: true,
          ),
        );
      }
    });
    await _billingPlatform.restorePurchases();
  }

  /// Releases the store subscription and the update stream.
  Future<void> dispose() async {
    _restoreTimer?.cancel();
    await _purchaseSubscription?.cancel();
    await _updates.close();
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final PurchaseDetails purchase in purchases) {
      if (purchase.status == PurchaseStatus.restored) {
        _restoredCount++;
        _restoreTimer?.cancel();
      }
      await _handlePurchase(purchase);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    switch (purchase.status) {
      case PurchaseStatus.pending:
        await _handlePending(purchase);
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        await _handleConfirmed(purchase);
      case PurchaseStatus.error:
        _emit(
          PurchaseUpdateEntity(
            status: PurchaseUpdateStatus.failed,
            productId: purchase.productID,
            error: purchase.error?.message,
          ),
        );
        await _billingPlatform.completePurchase(purchase);
      case PurchaseStatus.canceled:
        _emit(
          PurchaseUpdateEntity(
            status: PurchaseUpdateStatus.canceled,
            productId: purchase.productID,
          ),
        );
    }
  }

  Future<void> _handlePending(PurchaseDetails purchase) async {
    await _enqueuePending(purchase);
    _emit(
      PurchaseUpdateEntity(
        status: PurchaseUpdateStatus.pending,
        productId: purchase.productID,
      ),
    );
  }

  Future<void> _handleConfirmed(PurchaseDetails purchase) async {
    if (_remoteProvider.currentUserId == null) {
      await _enqueuePending(purchase);
      _emit(
        PurchaseUpdateEntity(
          status: PurchaseUpdateStatus.pending,
          productId: purchase.productID,
        ),
      );
      return;
    }

    final String? contourId = _resolveContourId(purchase.productID);
    try {
      await _verifyOnServer(purchase: purchase, contourId: contourId);
      await _billingPlatform.completePurchase(purchase);
      _emit(
        PurchaseUpdateEntity(
          status: PurchaseUpdateStatus.success,
          productId: purchase.productID,
          contourId: contourId,
          isRestore: purchase.status == PurchaseStatus.restored,
        ),
      );
    } catch (error, stackTrace) {
      ErrorHandler.report(error, stackTrace);
      await _enqueuePending(purchase);
      _emit(
        PurchaseUpdateEntity(
          status: PurchaseUpdateStatus.failed,
          productId: purchase.productID,
          contourId: contourId,
          error: error.toString(),
        ),
      );
    }
  }

  Future<void> _verifyOnServer({
    required PurchaseDetails purchase,
    required String? contourId,
  }) async {
    final String productId = purchase.productID;
    final bool isSubscription = RequestConstants.isSubscriptionProduct(productId);

    await _remoteProvider.verifyPurchase(
      productId: productId,
      purchaseToken: purchase.verificationData.serverVerificationData,
      type: isSubscription
          ? RequestConstants.purchaseTypeSubscription
          : RequestConstants.purchaseTypeProduct,
      platform: Platform.isIOS
          ? RequestConstants.platformApple
          : RequestConstants.platformGoogle,
      contourId: contourId,
    );
  }

  Future<void> _enqueuePending(PurchaseDetails purchase) async {
    final String? userId = _remoteProvider.currentUserId;
    if (userId == null) {
      return;
    }

    try {
      await enqueuePendingPurchase(
        userId: userId,
        productId: purchase.productID,
        purchaseToken: purchase.verificationData.serverVerificationData,
      );
    } catch (error, stackTrace) {
      ErrorHandler.report(error, stackTrace);
    }
  }

  String? _resolveContourId(String productId) {
    if (!productId.startsWith(RequestConstants.contourProductIdPrefix)) {
      return null;
    }
    return productId.substring(RequestConstants.contourProductIdPrefix.length);
  }

  BillingProductEntity _toProductEntity(ProductDetails product) {
    return BillingProductEntity(
      id: product.id,
      title: product.title,
      description: product.description,
      price: product.price,
      currencyCode: product.currencyCode,
      isSubscription: RequestConstants.isSubscriptionProduct(product.id),
    );
  }

  void _emit(PurchaseUpdateEntity update) {
    if (!_updates.isClosed) {
      _updates.add(update);
    }
  }
}
