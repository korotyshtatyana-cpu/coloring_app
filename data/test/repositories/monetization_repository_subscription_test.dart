import 'dart:async';

import 'package:core/core.dart';
import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class _FakeBillingPlatform implements BillingPlatform {
  final StreamController<List<PurchaseDetails>> purchasesController =
      StreamController<List<PurchaseDetails>>();

  int completeCalls = 0;
  int restoreCalls = 0;
  String? purchasedProductId;
  String? purchasedBasePlanId;
  String? currentProductId;
  String? currentBasePlanId;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream =>
      purchasesController.stream;

  @override
  Future<void> purchaseSubscription({
    required String productId,
    required String basePlanId,
    String? currentProductId,
    String? currentBasePlanId,
  }) async {
    purchasedProductId = productId;
    purchasedBasePlanId = basePlanId;
    this.currentProductId = currentProductId;
    this.currentBasePlanId = currentBasePlanId;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completeCalls++;
  }

  @override
  Future<void> restorePurchases() async {
    restoreCalls++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRemoteProvider implements MonetizationRemoteProvider {
  final List<Map<String, dynamic>> enqueued = <Map<String, dynamic>>[];
  final List<PendingPurchaseModel> pendingPurchases =
      <PendingPurchaseModel>[];
  final List<PendingPurchaseModel> resolvedPurchases =
      <PendingPurchaseModel>[];
  final List<SubscriptionModel> subscriptions = <SubscriptionModel>[];
  final List<SubscriptionPurchaseModel> subscriptionPurchases =
      <SubscriptionPurchaseModel>[];
  final List<UserEntitlementModel> purchasedEntitlements =
      <UserEntitlementModel>[];

  @override
  String? get currentUserId => 'user-1';

  @override
  Future<PurchaseVerificationResult> verifyPurchase({
    required String productId,
    required String purchaseToken,
    required String type,
    required String platform,
    String? contourId,
  }) async {
    throw StateError('verification failed');
  }

  @override
  Future<void> insertPendingPurchase(Map<String, dynamic> payload) async {
    enqueued.add(payload);
  }

  @override
  Future<List<PendingPurchaseModel>> getPendingPurchases(
    String userId,
  ) async {
    return pendingPurchases;
  }

  @override
  Future<List<PendingPurchaseModel>> getResolvedPurchases(
    String userId,
  ) async {
    return resolvedPurchases;
  }

  @override
  Future<List<SubscriptionModel>> getSubscriptions(String userId) async {
    return subscriptions;
  }

  @override
  Future<List<UserEntitlementModel>> getPurchasedEntitlements(
    String userId,
  ) async {
    return purchasedEntitlements;
  }

  @override
  Future<List<SubscriptionPurchaseModel>> getSubscriptionPurchases(
    String userId,
  ) async {
    return subscriptionPurchases;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRefundMonitor implements RefundMonitor {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSubscriptionCache implements SubscriptionCache {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLogger implements AppLogger {
  @override
  void setCrashReporter(CrashReporter? crashReporter) {}

  @override
  void debug(dynamic message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void error(dynamic message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void info(dynamic message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void warning(dynamic message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void verbose(dynamic message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void wtf(dynamic message, [Object? error, StackTrace? stackTrace]) {}
}

PurchaseDetails _subscriptionPurchase(PurchaseStatus status) {
  return PurchaseDetails(
    purchaseID: 'transaction-1',
    productID: 'no_ads',
    verificationData: PurchaseVerificationData(
      localVerificationData: '{}',
      serverVerificationData: 'purchase-token',
      source: 'test',
    ),
    transactionDate: null,
    status: status,
  );
}

PurchaseDetails _alreadyOwnedPurchase() {
  return PurchaseDetails(
      purchaseID: '',
      productID: '',
      verificationData: PurchaseVerificationData(
        localVerificationData: '',
        serverVerificationData: '',
        source: 'test',
      ),
      transactionDate: null,
      status: PurchaseStatus.error,
    )
    ..error = IAPError(
      source: 'google_play',
      code: 'purchase_error',
      message: 'BillingResponse.itemAlreadyOwned',
      details: 'ITEM_ALREADY_OWNED',
    );
}

SubscriptionModel _subscription({
  required String id,
  required String productId,
  required String? token,
  required DateTime startedAt,
  String? basePlanId,
}) {
  return SubscriptionModel(
    id: id,
    userId: 'user-1',
    productId: productId,
    planType: productId,
    basePlanId: basePlanId,
    isActive: true,
    startedAt: startedAt,
    expiresAt: startedAt.add(const Duration(days: 30)),
    purchaseToken: token,
    createdAt: startedAt,
    updatedAt: null,
  );
}

SubscriptionPurchaseModel _subscriptionPeriod({
  required String id,
  required String productId,
  required String token,
  required DateTime startedAt,
  required String basePlanId,
  bool isAutoRenewal = false,
}) {
  return SubscriptionPurchaseModel(
    id: id,
    userId: 'user-1',
    subscriptionId: 'subscription-1',
    purchaseToken: token,
    productId: productId,
    planType: productId,
    basePlanId: basePlanId,
    orderId: 'order-$id',
    isAutoRenewal: isAutoRenewal,
    startedAt: startedAt,
    expiresAt: startedAt.add(const Duration(days: 30)),
    createdAt: startedAt,
  );
}

PendingPurchaseModel _resolvedPending({
  required String id,
  required String productId,
  required String? token,
  required DateTime resolvedAt,
  String? contourId,
}) {
  return PendingPurchaseModel(
    id: id,
    userId: 'user-1',
    productId: productId,
    purchaseToken: token,
    contourId: contourId,
    status: PendingPurchaseStatus.resolved.dbValue,
    errorMessage: null,
    createdAt: resolvedAt,
    resolvedAt: resolvedAt,
  );
}

UserEntitlementModel _purchase({
  required String id,
  required String contourId,
  required String? token,
  required DateTime grantedAt,
  String? contourTitle,
  String? contourPreviewUrl,
}) {
  return UserEntitlementModel(
    id: id,
    userId: 'user-1',
    contourId: contourId,
    type: EntitlementType.purchase.dbValue,
    grantedAt: grantedAt,
    expiresAt: null,
    purchaseToken: token,
    contourTitle: contourTitle,
    contourPreviewUrl: contourPreviewUrl,
  );
}

void main() {
  group('MonetizationRepositoryImpl subscription purchase recovery', () {
    late _FakeBillingPlatform billing;
    late _FakeRemoteProvider remote;
    late MonetizationRepositoryImpl repository;

    setUp(() {
      ErrorHandler.setDelegate(null);
      appLocator.reset();
      billing = _FakeBillingPlatform();
      remote = _FakeRemoteProvider();
      final _FakeLogger logger = _FakeLogger();
      appLocator.registerSingleton<AppLogger>(logger);
      repository = MonetizationRepositoryImpl(
        remoteProvider: remote,
        billingPlatform: billing,
        refundMonitor: _FakeRefundMonitor(),
        subscriptionCache: _FakeSubscriptionCache(),
        analytics: AnalyticsService(logger: logger),
        logger: logger,
      );
    });

    tearDown(() async {
      await repository.dispose();
      await billing.purchasesController.close();
      await appLocator.reset();
      ErrorHandler.setDelegate(null);
    });

    test('verification failure after a confirmed subscription is pending, '
        'not failed, and the transaction is not acknowledged', () async {
      await repository.buySubscription(
        plan: SubscriptionPlanType.noAds,
        interval: SubscriptionInterval.month,
      );

      final Future<PurchaseUpdateEntity> update =
          repository.purchaseUpdates.first;
      billing.purchasesController.add(<PurchaseDetails>[
        _subscriptionPurchase(PurchaseStatus.purchased),
      ]);

      final PurchaseUpdateEntity result = await update;
      expect(result.status, PurchaseUpdateStatus.pending);
      expect(result.productId, SubscriptionPlanType.noAds.dbValue);
      expect(billing.completeCalls, 0);
      expect(remote.enqueued, isNotEmpty);
    });

    test(
      'an already owned item triggers restore instead of a failure',
      () async {
        final List<PurchaseUpdateEntity> updates = <PurchaseUpdateEntity>[];
        final StreamSubscription<PurchaseUpdateEntity> subscription = repository
            .purchaseUpdates
            .listen(updates.add);
        addTearDown(subscription.cancel);

        await repository.buySubscription(
          plan: SubscriptionPlanType.premium,
          interval: SubscriptionInterval.year,
        );
        billing.purchasesController.add(<PurchaseDetails>[
          _alreadyOwnedPurchase(),
        ]);

        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(billing.restoreCalls, 1);
        expect(
          updates.where(
            (PurchaseUpdateEntity update) =>
                update.status == PurchaseUpdateStatus.failed,
          ),
          isEmpty,
        );
      },
    );

    test('does not queue the same purchase token twice', () async {
      remote.pendingPurchases.add(
        PendingPurchaseModel(
          id: 'pending-1',
          userId: 'user-1',
          productId: SubscriptionPlanType.noAds.dbValue,
          purchaseToken: 'purchase-token',
          contourId: null,
          status: RequestConstants.pendingPurchaseStatusPending,
          errorMessage: null,
          createdAt: DateTime.now(),
          resolvedAt: null,
        ),
      );

      final Future<PurchaseUpdateEntity> update =
          repository.purchaseUpdates.first;
      await repository.buySubscription(
        plan: SubscriptionPlanType.noAds,
        interval: SubscriptionInterval.month,
      );
      billing.purchasesController.add(<PurchaseDetails>[
        _subscriptionPurchase(PurchaseStatus.purchased),
      ]);

      final PurchaseUpdateEntity result = await update;
      expect(result.status, PurchaseUpdateStatus.pending);
      expect(remote.enqueued, isEmpty);
    });

    test('passes the owned subscription to the billing platform', () async {
      await repository.buySubscription(
        plan: SubscriptionPlanType.premium,
        interval: SubscriptionInterval.year,
        currentProductId: SubscriptionPlanType.noAds.dbValue,
        currentBasePlanId: SubscriptionInterval.week.dbValue,
      );

      expect(billing.purchasedProductId, SubscriptionPlanType.premium.dbValue);
      expect(billing.purchasedBasePlanId, SubscriptionInterval.year.dbValue);
      expect(billing.currentProductId, SubscriptionPlanType.noAds.dbValue);
      expect(billing.currentBasePlanId, SubscriptionInterval.week.dbValue);
    });
  });

  group('MonetizationRepositoryImpl purchase history', () {
    late _FakeBillingPlatform billing;
    late _FakeRemoteProvider remote;
    late MonetizationRepositoryImpl repository;

    setUp(() {
      billing = _FakeBillingPlatform();
      remote = _FakeRemoteProvider();
      final _FakeLogger logger = _FakeLogger();
      repository = MonetizationRepositoryImpl(
        remoteProvider: remote,
        billingPlatform: billing,
        refundMonitor: _FakeRefundMonitor(),
        subscriptionCache: _FakeSubscriptionCache(),
        analytics: AnalyticsService(logger: logger),
        logger: logger,
      );
    });

    tearDown(() async {
      await repository.dispose();
      await billing.purchasesController.close();
    });

    test('includes subscriptions that never entered the pending queue',
        () async {
      final DateTime olderPurchase = DateTime.utc(2026, 11, 1, 10);
      final DateTime subscriptionStartedAt = DateTime.utc(2026, 11, 10, 12);
      remote.resolvedPurchases.add(
        _resolvedPending(
          id: 'pending-1',
          productId: 'no_ads',
          token: 'old-token',
          resolvedAt: olderPurchase,
        ),
      );
      remote.subscriptions.add(
        _subscription(
          id: 'subscription-1',
          productId: 'premium',
          token: 'new-token',
          startedAt: subscriptionStartedAt,
          basePlanId: 'week',
        ),
      );

      final List<PendingPurchaseEntity> history = await repository
          .getResolvedPurchases('user-1');

      expect(history, hasLength(2));
      expect(history.first.productId, 'premium');
      expect(history.first.status, PendingPurchaseStatus.resolved);
      expect(history.first.resolvedAt, subscriptionStartedAt);
      expect(history.first.subscriptionInterval, SubscriptionInterval.week);
      expect(history.last.productId, 'no_ads');
    });

    test('does not duplicate a subscription already in pending history',
        () async {
      final DateTime resolvedAt = DateTime.utc(2026, 11, 10, 12);
      remote.resolvedPurchases.add(
        _resolvedPending(
          id: 'pending-1',
          productId: 'premium',
          token: 'shared-token',
          resolvedAt: resolvedAt,
        ),
      );
      remote.subscriptions.add(
        _subscription(
          id: 'subscription-1',
          productId: 'premium',
          token: 'shared-token',
          startedAt: resolvedAt,
        ),
      );

      final List<PendingPurchaseEntity> history = await repository
          .getResolvedPurchases('user-1');

      expect(history, hasLength(1));
      expect(history.single.id, 'pending-1');
    });

    test('lists every paid period with its interval and renewal flag',
        () async {
      final DateTime firstPeriod = DateTime.utc(2026, 10, 10, 12);
      final DateTime secondPeriod = DateTime.utc(2026, 11, 10, 12);
      remote.subscriptionPurchases.addAll(<SubscriptionPurchaseModel>[
        _subscriptionPeriod(
          id: 'period-2',
          productId: 'premium',
          token: 'shared-token',
          startedAt: secondPeriod,
          basePlanId: 'month',
          isAutoRenewal: true,
        ),
        _subscriptionPeriod(
          id: 'period-1',
          productId: 'premium',
          token: 'shared-token',
          startedAt: firstPeriod,
          basePlanId: 'month',
        ),
      ]);
      remote.subscriptions.add(
        _subscription(
          id: 'subscription-1',
          productId: 'premium',
          token: 'shared-token',
          startedAt: firstPeriod,
          basePlanId: 'month',
        ),
      );

      final List<PendingPurchaseEntity> history = await repository
          .getResolvedPurchases('user-1');

      expect(history, hasLength(2));
      expect(history.first.id, 'period-2');
      expect(history.first.subscriptionInterval, SubscriptionInterval.month);
      expect(history.first.isAutoRenewal, isTrue);
      expect(history.last.id, 'period-1');
      expect(history.last.subscriptionInterval, SubscriptionInterval.month);
      expect(history.last.isAutoRenewal, isFalse);
    });

    test('a stored period replaces the generic subscription and pending rows',
        () async {
      final DateTime startedAt = DateTime.utc(2026, 11, 10, 12);
      remote.subscriptionPurchases.add(
        _subscriptionPeriod(
          id: 'period-1',
          productId: 'premium',
          token: 'shared-token',
          startedAt: startedAt,
          basePlanId: 'year',
        ),
      );
      remote.subscriptions.add(
        _subscription(
          id: 'subscription-1',
          productId: 'premium',
          token: 'shared-token',
          startedAt: startedAt,
          basePlanId: 'year',
        ),
      );
      remote.resolvedPurchases.add(
        _resolvedPending(
          id: 'pending-1',
          productId: 'premium',
          token: 'shared-token',
          resolvedAt: startedAt,
        ),
      );

      final List<PendingPurchaseEntity> history = await repository
          .getResolvedPurchases('user-1');

      expect(history, hasLength(1));
      expect(history.single.id, 'period-1');
      expect(history.single.subscriptionInterval, SubscriptionInterval.year);
      expect(history.single.isAutoRenewal, isFalse);
    });

    test('includes one-time project purchases with contour details', () async {
      final DateTime grantedAt = DateTime.utc(2026, 11, 9, 8);
      remote.purchasedEntitlements.add(
        _purchase(
          id: 'entitlement-1',
          contourId: 'contour-1',
          token: 'project-token',
          grantedAt: grantedAt,
          contourTitle: 'Котёнок',
          contourPreviewUrl: 'https://example.com/cat.png',
        ),
      );

      final List<PendingPurchaseEntity> history = await repository
          .getResolvedPurchases('user-1');

      expect(history, hasLength(1));
      final PendingPurchaseEntity purchase = history.single;
      expect(purchase.contourId, 'contour-1');
      expect(purchase.contourTitle, 'Котёнок');
      expect(purchase.contourPreviewUrl, 'https://example.com/cat.png');
      expect(purchase.status, PendingPurchaseStatus.resolved);
      expect(purchase.resolvedAt, grantedAt);
    });

    test('enriches a resolved pending project row with contour details',
        () async {
      final DateTime resolvedAt = DateTime.utc(2026, 11, 9, 8);
      remote.resolvedPurchases.add(
        _resolvedPending(
          id: 'pending-1',
          productId: 'contour_contour-1',
          token: 'shared-project-token',
          resolvedAt: resolvedAt,
          contourId: 'contour-1',
        ),
      );
      remote.purchasedEntitlements.add(
        _purchase(
          id: 'entitlement-1',
          contourId: 'contour-1',
          token: 'shared-project-token',
          grantedAt: resolvedAt,
          contourTitle: 'Котёнок',
          contourPreviewUrl: 'https://example.com/cat.png',
        ),
      );

      final List<PendingPurchaseEntity> history = await repository
          .getResolvedPurchases('user-1');

      expect(history, hasLength(1));
      final PendingPurchaseEntity purchase = history.single;
      expect(purchase.id, 'pending-1');
      expect(purchase.contourTitle, 'Котёнок');
      expect(purchase.contourPreviewUrl, 'https://example.com/cat.png');
    });
  });
}
