import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:domain/domain.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../data.dart';

/// Implementation of [MonetizationRepository] using
/// [MonetizationRemoteProvider] and [BillingPlatform].
///
/// Access is always resolved from server-provided state: subscription and No
/// Ads reads are served through [SubscriptionCache], which only shortens
/// repeated gallery reads and never grants access past a subscription's own
/// expiry. The cache is invalidated after every confirmed purchase or restore,
/// so a completed purchase is never hidden by a stale entry.
///
/// Confirmed store transactions are verified on the server before the
/// entitlement is granted. Failures are queued in `pending_purchases` and
/// resolved on a later check.
class MonetizationRepositoryImpl implements MonetizationRepository {
  final MonetizationRemoteProvider _remoteProvider;
  final BillingPlatform _billingPlatform;
  final RefundMonitor _refundMonitor;
  final SubscriptionCache _subscriptionCache;
  final AnalyticsService _analytics;
  final AppLogger _logger;
  final StreamController<PurchaseUpdateEntity> _updates =
      StreamController<PurchaseUpdateEntity>.broadcast();

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  Timer? _restoreTimer;
  int _restoredCount = 0;
  String? _pendingCreditContourId;

  /// Creates a repository with the given [_remoteProvider], [_billingPlatform],
  /// [_subscriptionCache], [_analytics] and [_logger].
  MonetizationRepositoryImpl({
    required this._remoteProvider,
    required this._billingPlatform,
    required this._refundMonitor,
    required this._subscriptionCache,
    required this._analytics,
    required this._logger,
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
    final SubscriptionModel? cached = _subscriptionCache.readSubscription(
      userId,
    );
    if (cached != null) {
      return SubscriptionMapper.toEntity(cached);
    }

    final SubscriptionModel? previous = _subscriptionCache.readLastSubscription(
      userId,
    );
    final SubscriptionModel? model = await _remoteProvider
        .getActiveSubscription(userId);

    // An active-to-none transition means the plan expired (or was revoked);
    // report it once, right when it is observed.
    if (model == null && previous != null && previous.isActive) {
      _logger.debug(
        '[Monetization] Subscription expired: product=${previous.productId}',
      );
      _analytics.logEvent(
        AnalyticsEvents.subscriptionExpired,
        parameters: <String, Object?>{
          'plan_type': previous.planType,
          'product_id': previous.productId,
        },
      );
    }

    // An inactive-to-active transition means a renewal or a restored plan.
    if (model != null &&
        model.isActive &&
        previous != null &&
        !previous.isActive) {
      _logger.debug(
        '[Monetization] Subscription activated: plan=${model.planType}',
      );
    }

    _subscriptionCache.writeSubscription(userId, model);
    return model == null ? null : SubscriptionMapper.toEntity(model);
  }

  @override
  Future<bool> isNoAdsPurchased(String userId) async {
    final bool? cached = _subscriptionCache.readNoAds(userId);
    if (cached != null) {
      return cached;
    }

    final bool purchased = await _remoteProvider.getNoAdsFlag(userId);
    _subscriptionCache.writeNoAds(userId, purchased);
    return purchased;
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
    final List<UserEntitlementModel> models = await _remoteProvider
        .getAllEntitlements(userId);

    return models
        .map(UserEntitlementMapper.toEntity)
        .whereType<UserEntitlementEntity>()
        .toList();
  }

  @override
  Future<void> grantRewardedUnlock({
    required String userId,
    required String contourId,
  }) {
    return _remoteProvider.insertEntitlement(<String, dynamic>{
      RequestConstants.userIdColumn: userId,
      RequestConstants.contourIdColumn: contourId,
      RequestConstants.typeColumn:
          RequestConstants.entitlementTypeRewardedUnlock,
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
    String? contourId,
  }) {
    return _remoteProvider.insertPendingPurchase(<String, dynamic>{
      RequestConstants.userIdColumn: userId,
      RequestConstants.productIdColumn: productId,
      RequestConstants.purchaseTokenColumn: purchaseToken,
      RequestConstants.contourIdColumn: contourId,
      RequestConstants.statusColumn:
          RequestConstants.pendingPurchaseStatusPending,
    });
  }

  @override
  Future<List<PendingPurchaseEntity>> getPendingPurchases(String userId) async {
    final List<PendingPurchaseModel> models = await _remoteProvider
        .getPendingPurchases(userId);
    return models.map(PendingPurchaseMapper.toEntity).toList();
  }

  @override
  Future<PendingPurchaseRefreshStatus> refreshPendingPurchase(
    PendingPurchaseEntity purchase,
  ) async {
    final String token = purchase.purchaseToken ?? '';
    if (token.isEmpty) {
      // Without a store token the only reliable check is the server-side
      // entitlement that a confirmed purchase would have granted.
      return _refreshPendingFromEntitlement(purchase);
    }

    final PurchaseVerificationResult result = await _remoteProvider
        .verifyPurchase(
          productId: purchase.productId,
          purchaseToken: token,
          type: _purchaseTypeOf(purchase.productId),
          platform: Platform.isIOS
              ? RequestConstants.platformApple
              : RequestConstants.platformGoogle,
          contourId: purchase.contourId,
        );
    if (result == PurchaseVerificationResult.pending) {
      return PendingPurchaseRefreshStatus.pending;
    }
    if (result == PurchaseVerificationResult.failed) {
      return PendingPurchaseRefreshStatus.failed;
    }

    _subscriptionCache.invalidate();
    return PendingPurchaseRefreshStatus.verified;
  }

  Future<PendingPurchaseRefreshStatus> _refreshPendingFromEntitlement(
    PendingPurchaseEntity purchase,
  ) async {
    final String? userId = _remoteProvider.currentUserId;
    final String? contourId = purchase.contourId;
    if (userId == null || contourId == null) {
      return PendingPurchaseRefreshStatus.pending;
    }

    final UserEntitlementEntity? entitlement = await getEntitlement(
      userId: userId,
      contourId: contourId,
    );
    if (entitlement == null) {
      return PendingPurchaseRefreshStatus.pending;
    }

    _subscriptionCache.invalidate();
    return PendingPurchaseRefreshStatus.verified;
  }

  @override
  Future<List<PendingPurchaseEntity>> getResolvedPurchases(
    String userId,
  ) async {
    final List<PendingPurchaseModel> models = await _remoteProvider
        .getResolvedPurchases(userId);
    return models.map(PendingPurchaseMapper.toEntity).toList();
  }

  @override
  Future<List<PurchaseRefundEntity>> getUnacknowledgedRefunds(
    String userId,
  ) async {
    final List<PurchaseRefundModel> models = await _remoteProvider
        .getUnacknowledgedRefunds(userId);
    if (models.isNotEmpty) {
      // A refund may revoke a subscription or the No Ads plan. Drop cached
      // access immediately so this same status load resolves the new state
      // instead of trusting a still-fresh cached value.
      _subscriptionCache.invalidate();
      // Refunds discovered by polling must reach the same listeners as
      // realtime ones, so both paths feed the single refund stream.
      _refundMonitor.emitFetched(models);
    }
    return models
        .map((PurchaseRefundModel model) => PurchaseRefundMapper.toEntity(model))
        .toList();
  }

  @override
  Stream<PurchaseRefundEntity> watchRefunds(String userId) {
    return _refundMonitor.watchRefunds(userId).asyncMap(_toRefundEntity);
  }

  /// Maps a refund row to an entity, resolving the contour it unlocked and
  /// dropping the subscription cache so the next access read is fresh.
  Future<PurchaseRefundEntity> _toRefundEntity(
    PurchaseRefundModel model,
  ) async {
    // A refund may revoke a subscription or the No Ads plan, so any cached
    // access state must not survive the event.
    _subscriptionCache.invalidate();
    final String? contourId = await _resolveRefundedContour(model);
    _logger.debug(
      '[Monetization] refund event received: '
      'token=${_lastTokenChars(model.purchaseToken)}, '
      'product=${model.productId}',
    );
    return PurchaseRefundMapper.toEntity(model, affectedContourId: contourId);
  }

  /// Best-effort resolution of the contour a refunded purchase unlocked.
  ///
  /// Individual project purchases encode the contour in the product id. For a
  /// credit refund the contour is recovered from the purchase history; the
  /// refund row itself does not carry it.
  Future<String?> _resolveRefundedContour(PurchaseRefundModel model) async {
    final String productId = model.productId;
    if (productId.startsWith(RequestConstants.contourProductIdPrefix)) {
      return productId.substring(
        RequestConstants.contourProductIdPrefix.length,
      );
    }
    if (productId == RequestConstants.creditProductId) {
      final String? contourId = await _storedContourIdForToken(
        model.purchaseToken,
      );
      if (contourId == null) {
        _logger.warning(
          '[Monetization] failed to resolve affected contour for credit '
          'refund: token=${_lastTokenChars(model.purchaseToken)}',
        );
      }
      return contourId;
    }
    return null;
  }

  @override
  Future<void> acknowledgeRefund(String refundId) {
    return _remoteProvider.acknowledgeRefund(refundId);
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
  Future<BillingProductEntity?> getCreditProduct() async {
    final List<ProductDetails> products = await _billingPlatform.queryProducts(
      <String>[RequestConstants.creditProductId],
    );
    for (final ProductDetails product in products) {
      if (product.id == RequestConstants.creditProductId) {
        return _toProductEntity(product);
      }
    }
    return null;
  }

  @override
  Future<void> buySubscription({
    required SubscriptionPlanType plan,
    required SubscriptionInterval interval,
  }) {
    final String productId = RequestConstants.subscriptionProductId(
      plan,
      interval,
    );
    _analytics.logEvent(
      AnalyticsEvents.purchaseStarted,
      parameters: <String, Object?>{
        'type': RequestConstants.purchaseTypeSubscription,
        'product_id': productId,
        'plan_type': plan.dbValue,
        'interval': interval.dbValue,
      },
    );
    return _billingPlatform.purchase(productId);
  }

  @override
  Future<void> buyProject({required String contourId, String? productId}) {
    final String resolvedProductId =
        productId ?? '${RequestConstants.contourProductIdPrefix}$contourId';
    _logger.debug(
      '[Monetization] Purchase initiated: product=$resolvedProductId, '
      'type=${RequestConstants.purchaseTypeProduct}',
    );
    _analytics.logEvent(
      AnalyticsEvents.purchaseStarted,
      parameters: <String, Object?>{
        'type': RequestConstants.purchaseTypeProduct,
        'product_id': resolvedProductId,
        'contour_id': contourId,
      },
    );
    return _billingPlatform.purchase(resolvedProductId);
  }

  @override
  Future<void> buyCredit({required String contourId}) {
    _pendingCreditContourId = contourId;
    _logger.debug(
      '[Monetization] Credit purchase initiated: '
      'product=${RequestConstants.creditProductId}, contour=$contourId',
    );
    _analytics.logEvent(
      AnalyticsEvents.purchaseStarted,
      parameters: <String, Object?>{
        'type': RequestConstants.purchaseTypeCredits,
        'product_id': RequestConstants.creditProductId,
        'contour_id': contourId,
      },
    );
    return _billingPlatform.purchaseConsumable(
      RequestConstants.creditProductId,
    );
  }

  @override
  Future<void> restorePurchases() async {
    _logger.debug('[Monetization] Restore started');
    _restoredCount = 0;
    _restoreTimer?.cancel();
    _restoreTimer = Timer(RequestConstants.restoreResultTimeout, () {
      _logger.debug('[Monetization] Restore completed: count=$_restoredCount');
      if (_restoredCount == 0) {
        _emit(
          const PurchaseUpdateEntity(
            status: PurchaseUpdateStatus.empty,
            isRestore: true,
          ),
        );
      }
    });
    try {
      await _billingPlatform.restorePurchases();
    } catch (error) {
      _logger.error('[Monetization] Restore failed: error=$error');
      rethrow;
    }
  }

  /// Releases the store subscription and the update stream.
  Future<void> dispose() async {
    _restoreTimer?.cancel();
    await _purchaseSubscription?.cancel();
    await _updates.close();
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    bool restoredInBatch = false;
    for (final PurchaseDetails purchase in purchases) {
      if (purchase.status == PurchaseStatus.restored) {
        _restoredCount++;
        _restoreTimer?.cancel();
        restoredInBatch = true;
      }
      await _handlePurchase(purchase);
    }
    if (restoredInBatch) {
      _logger.debug('[Monetization] Restore completed: count=$_restoredCount');
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
        // Store-level errors (for example billingUnavailable) arrive without a
        // product id because no transaction was created. Attribute them to the
        // purchase flow that is currently in progress so the UI can react.
        final String errorProductId = _resolveProductId(purchase);
        final String? contourId = _resolveContourId(errorProductId);
        _logger.warning(
          '[Monetization] Purchase failed: product=$errorProductId, '
          'error=${purchase.error?.message ?? 'unknown'}',
        );
        _analytics.logEvent(
          AnalyticsEvents.purchaseFailed,
          parameters: <String, Object?>{
            'product_id': errorProductId,
            'reason': purchase.error?.message,
          },
        );
        _clearPendingCreditContour(errorProductId);
        _emit(
          PurchaseUpdateEntity(
            status: PurchaseUpdateStatus.failed,
            productId: errorProductId,
            contourId: contourId,
            error: purchase.error?.message,
          ),
        );
      // There is no transaction to finish for an error purchase; calling
      // completePurchase would throw an assertion on Android.
      case PurchaseStatus.canceled:
        // Google Play can report a dismissed purchase without a product id.
        // Resolve it from the active flow just like a store-level error so the
        // dialog recognizes the cancellation and stops its loading state.
        final String productId = _resolveProductId(purchase);
        final String? contourId = _resolveContourId(productId);
        _analytics.logEvent(
          AnalyticsEvents.purchaseCanceled,
          parameters: <String, Object?>{'product_id': productId},
        );
        _clearPendingCreditContour(productId);
        _emit(
          PurchaseUpdateEntity(
            status: PurchaseUpdateStatus.canceled,
            productId: productId,
            contourId: contourId,
          ),
        );
    }
  }

  Future<void> _handlePending(PurchaseDetails purchase) async {
    final String? contourId =
        _resolveContourId(purchase.productID) ??
        await _storedContourIdForToken(
          purchase.verificationData.serverVerificationData,
        );
    await _enqueuePending(purchase, contourId: contourId);
    _logger.debug(
      '[Monetization] Purchase pending: product=${purchase.productID}, '
      'token=${_shortToken(purchase.verificationData.serverVerificationData)}',
    );
    _analytics.logEvent(
      AnalyticsEvents.purchasePending,
      parameters: <String, Object?>{'product_id': purchase.productID},
    );
    _emit(
      PurchaseUpdateEntity(
        status: PurchaseUpdateStatus.pending,
        productId: purchase.productID,
        contourId: contourId,
      ),
    );
  }

  Future<void> _handleConfirmed(PurchaseDetails purchase) async {
    final bool isRestore = purchase.status == PurchaseStatus.restored;
    final String token = purchase.verificationData.serverVerificationData;
    String? contourId;
    if (!isRestore) {
      contourId = _resolveContourId(purchase.productID);
    }
    // A credit purchase re-delivered after an app restart no longer knows the
    // contour from memory; recover it from the queued pending row.
    final bool canRecoverContour = !RequestConstants.isSubscriptionProduct(
      purchase.productID,
    );
    if (contourId == null && canRecoverContour) {
      contourId = await _storedContourIdForToken(token);
    }

    if (_remoteProvider.currentUserId == null) {
      await _enqueuePending(purchase, contourId: contourId);
      _emit(
        PurchaseUpdateEntity(
          status: PurchaseUpdateStatus.pending,
          productId: purchase.productID,
          contourId: contourId,
        ),
      );
      return;
    }

    try {
      final PurchaseVerificationResult verification = await _verifyOnServer(
        purchase: purchase,
        contourId: contourId,
      );
      if (verification == PurchaseVerificationResult.pending) {
        await _handlePending(purchase);
        return;
      }
      if (verification == PurchaseVerificationResult.failed) {
        _logger.warning(
          '[Monetization] Purchase rejected by store: '
          'product=${purchase.productID}',
        );
        _clearPendingCreditContour(purchase.productID);
        _emit(
          PurchaseUpdateEntity(
            status: PurchaseUpdateStatus.failed,
            productId: purchase.productID,
            contourId: contourId,
            isRestore: isRestore,
            error: 'Purchase was canceled by Google Play',
          ),
        );
        return;
      }

      await _billingPlatform.completePurchase(purchase);
      if (!isRestore) {
        _clearPendingCreditContour(purchase.productID);
      }

      // A purchase just changed the server state; drop the cache so the next
      // gallery read reflects the new access immediately.
      _subscriptionCache.invalidate();
      _logger.debug(
        '[Monetization] Purchase completed: product=${purchase.productID}, '
        'token=${_shortToken(purchase.verificationData.serverVerificationData)}',
      );
      if (RequestConstants.isSubscriptionProduct(purchase.productID)) {
        _logger.debug(
          '[Monetization] Subscription activated: '
          'plan=${_subscriptionPlanOf(purchase.productID)}',
        );
      }
      _analytics.logEvent(
        AnalyticsEvents.purchaseCompleted,
        parameters: <String, Object?>{
          'product_id': purchase.productID,
          'contour_id': contourId,
          'is_restore': isRestore,
        },
      );
      _emit(
        PurchaseUpdateEntity(
          status: PurchaseUpdateStatus.success,
          productId: purchase.productID,
          contourId: contourId,
          isRestore: isRestore,
        ),
      );
    } catch (error, stackTrace) {
      ErrorHandler.report(error, stackTrace);
      _logger.error(
        '[Monetization] Purchase failed: product=${purchase.productID}, '
        'error=$error',
      );
      _analytics.logEvent(
        AnalyticsEvents.purchaseFailed,
        parameters: <String, Object?>{
          'product_id': purchase.productID,
          'contour_id': contourId,
          'reason': error.toString(),
        },
      );
      await _enqueuePending(purchase, contourId: contourId);
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

  Future<PurchaseVerificationResult> _verifyOnServer({
    required PurchaseDetails purchase,
    required String? contourId,
  }) async {
    return _remoteProvider.verifyPurchase(
      productId: purchase.productID,
      purchaseToken: purchase.verificationData.serverVerificationData,
      type: _purchaseTypeOf(purchase.productID),
      platform: Platform.isIOS
          ? RequestConstants.platformApple
          : RequestConstants.platformGoogle,
      contourId: contourId,
    );
  }

  String _purchaseTypeOf(String productId) {
    if (RequestConstants.isSubscriptionProduct(productId)) {
      return RequestConstants.purchaseTypeSubscription;
    }
    if (productId == RequestConstants.creditProductId) {
      return RequestConstants.purchaseTypeCredits;
    }
    return RequestConstants.purchaseTypeProduct;
  }

  Future<void> _enqueuePending(
    PurchaseDetails purchase, {
    String? contourId,
  }) async {
    final String? userId = _remoteProvider.currentUserId;
    if (userId == null) {
      return;
    }

    try {
      await enqueuePendingPurchase(
        userId: userId,
        productId: purchase.productID,
        purchaseToken: purchase.verificationData.serverVerificationData,
        contourId: contourId,
      );
    } catch (error, stackTrace) {
      ErrorHandler.report(error, stackTrace);
    }
  }

  /// Looks up the contour stored for a queued or already resolved purchase
  /// with [purchaseToken].
  ///
  /// A restored transaction arrives without the product-to-contour mapping the
  /// original buy had, so the contour is recovered from the stored row.
  Future<String?> _storedContourIdForToken(String purchaseToken) async {
    final String? userId = _remoteProvider.currentUserId;
    if (userId == null || purchaseToken.isEmpty) {
      return null;
    }

    try {
      final List<PendingPurchaseEntity> pending = await getPendingPurchases(
        userId,
      );
      for (final PendingPurchaseEntity purchase in pending) {
        if (purchase.purchaseToken == purchaseToken) {
          return purchase.contourId;
        }
      }

      final List<PendingPurchaseEntity> resolved = await getResolvedPurchases(
        userId,
      );
      for (final PendingPurchaseEntity purchase in resolved) {
        if (purchase.purchaseToken == purchaseToken) {
          return purchase.contourId;
        }
      }
    } catch (error, stackTrace) {
      ErrorHandler.report(error, stackTrace);
    }
    return null;
  }

  String _resolveProductId(PurchaseDetails purchase) {
    if (purchase.productID.isNotEmpty) {
      return purchase.productID;
    }
    if (_pendingCreditContourId != null) {
      return RequestConstants.creditProductId;
    }
    return purchase.productID;
  }

  String? _resolveContourId(String productId) {
    if (productId == RequestConstants.creditProductId) {
      return _pendingCreditContourId;
    }
    if (!productId.startsWith(RequestConstants.contourProductIdPrefix)) {
      return null;
    }
    return productId.substring(RequestConstants.contourProductIdPrefix.length);
  }

  void _clearPendingCreditContour(String productId) {
    if (productId == RequestConstants.creditProductId) {
      _pendingCreditContourId = null;
    }
  }

  String _shortToken(String token) {
    if (token.isEmpty) {
      return 'none';
    }
    return token.length <= 8 ? token : '${token.substring(0, 8)}...';
  }

  String _lastTokenChars(String token) {
    if (token.isEmpty) {
      return 'none';
    }
    return token.length <= 8 ? token : token.substring(token.length - 8);
  }

  String _subscriptionPlanOf(String productId) {
    return productId.startsWith(SubscriptionPlanType.premium.dbValue)
        ? SubscriptionPlanType.premium.dbValue
        : SubscriptionPlanType.noAds.dbValue;
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
