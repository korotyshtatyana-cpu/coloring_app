import 'package:domain/domain.dart';

import '../../data.dart';

/// Implementation of [MonetizationRepository] using
/// [MonetizationRemoteProvider].
///
/// Every value is resolved from the server on each call: the app has no
/// offline mode, so nothing here caches access decisions or falls back to a
/// previous subscription state.
class MonetizationRepositoryImpl implements MonetizationRepository {
  final MonetizationRemoteProvider _remoteProvider;

  /// Creates a repository with the given [_remoteProvider].
  MonetizationRepositoryImpl({required this._remoteProvider});

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
}
