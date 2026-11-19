import 'dart:async';

import 'package:core/core.dart';
import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class _FakeBillingPlatform implements BillingPlatform {
  final StreamController<List<PurchaseDetails>> purchasesController;

  _FakeBillingPlatform(this.purchasesController);

  @override
  Stream<List<PurchaseDetails>> get purchaseStream =>
      purchasesController.stream;

  @override
  Future<void> purchaseConsumable(String productId) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRemoteProvider implements MonetizationRemoteProvider {
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

void main() {
  group('MonetizationRepositoryImpl purchase cancellation', () {
    late StreamController<List<PurchaseDetails>> purchasesController;
    late MonetizationRepositoryImpl repository;

    setUp(() {
      purchasesController = StreamController<List<PurchaseDetails>>();
      final logger = _FakeLogger();
      repository = MonetizationRepositoryImpl(
        remoteProvider: _FakeRemoteProvider(),
        billingPlatform: _FakeBillingPlatform(purchasesController),
        refundMonitor: _FakeRefundMonitor(),
        subscriptionCache: _FakeSubscriptionCache(),
        analytics: AnalyticsService(logger: logger),
        logger: logger,
      );
    });

    tearDown(() async {
      await repository.dispose();
      await purchasesController.close();
    });

    test('empty store product id is resolved for the active credit purchase', () async {
      await repository.buyCredit(contourId: 'contour_1');
      final expectation = expectLater(
        repository.purchaseUpdates,
        emits(
          predicate<PurchaseUpdateEntity>(
            (update) =>
                update.status == PurchaseUpdateStatus.canceled &&
                update.productId == RequestConstants.creditProductId &&
                update.contourId == 'contour_1',
          ),
        ),
      );

      purchasesController.add(<PurchaseDetails>[
        PurchaseDetails(
          purchaseID: null,
          productID: '',
          verificationData: PurchaseVerificationData(
            localVerificationData: '',
            serverVerificationData: '',
            source: 'test',
          ),
          transactionDate: null,
          status: PurchaseStatus.canceled,
        ),
      ]);

      await expectation;
    });
  });
}
