import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('hasStaleSubscriptionPending', () {
    final DateTime now = DateTime.utc(2026, 11, 10, 12);
    const Duration threshold = Duration(hours: 24);

    test('reports an old subscription that never activated', () {
      final PendingPurchaseEntity failedAt = _pending(
        id: 'failed',
        productId: 'no_ads',
        createdAt: now.subtract(const Duration(days: 2)),
      );

      expect(
        hasStaleSubscriptionPending(
          pending: <PendingPurchaseEntity>[failedAt],
          history: const <PendingPurchaseEntity>[],
          now: now,
          threshold: threshold,
        ),
        isTrue,
      );
    });

    test('ignores a pending purchase newer than the threshold', () {
      final PendingPurchaseEntity failedAt = _pending(
        id: 'failed',
        productId: 'no_ads',
        createdAt: now.subtract(const Duration(hours: 2)),
      );

      expect(
        hasStaleSubscriptionPending(
          pending: <PendingPurchaseEntity>[failedAt],
          history: const <PendingPurchaseEntity>[],
          now: now,
          threshold: threshold,
        ),
        isFalse,
      );
    });

    test('ignores an old one-time project purchase', () {
      final PendingPurchaseEntity failedAt = _pending(
        id: 'failed',
        productId: 'contour_1',
        createdAt: now.subtract(const Duration(days: 2)),
      );

      expect(
        hasStaleSubscriptionPending(
          pending: <PendingPurchaseEntity>[failedAt],
          history: const <PendingPurchaseEntity>[],
          now: now,
          threshold: threshold,
        ),
        isFalse,
      );
    });

    test('an active newer subscription supersedes the failed attempt', () {
      final PendingPurchaseEntity failedAt = _pending(
        id: 'failed',
        productId: 'no_ads',
        createdAt: now.subtract(const Duration(days: 2)),
      );
      final DateTime startedAt = now.subtract(const Duration(days: 1));

      expect(
        hasStaleSubscriptionPending(
          pending: <PendingPurchaseEntity>[failedAt],
          history: const <PendingPurchaseEntity>[],
          now: now,
          threshold: threshold,
          activeSubscriptionStartedAt: startedAt,
        ),
        isFalse,
      );
    });

    test('a successful subscription keeps the notice hidden after it expires',
        () {
      // The test subscription ended, but it still proves that the earlier
      // failed setup was superseded and must not be reported again.
      final PendingPurchaseEntity failedAt = _pending(
        id: 'failed',
        productId: 'no_ads',
        createdAt: now.subtract(const Duration(days: 2)),
      );
      final PendingPurchaseEntity paidAt = _pending(
        id: 'paid',
        productId: 'no_ads',
        createdAt: now.subtract(const Duration(days: 1)),
        status: PendingPurchaseStatus.resolved,
      );

      expect(
        hasStaleSubscriptionPending(
          pending: <PendingPurchaseEntity>[failedAt],
          history: <PendingPurchaseEntity>[paidAt],
          now: now,
          threshold: threshold,
        ),
        isFalse,
      );
    });

    test('a failed attempt after a successful subscription is still reported',
        () {
      final PendingPurchaseEntity paidAt = _pending(
        id: 'paid',
        productId: 'no_ads',
        createdAt: now.subtract(const Duration(days: 3)),
        status: PendingPurchaseStatus.resolved,
      );
      final PendingPurchaseEntity failedAt = _pending(
        id: 'failed',
        productId: 'premium',
        createdAt: now.subtract(const Duration(days: 2)),
      );

      expect(
        hasStaleSubscriptionPending(
          pending: <PendingPurchaseEntity>[failedAt],
          history: <PendingPurchaseEntity>[paidAt],
          now: now,
          threshold: threshold,
        ),
        isTrue,
      );
    });
  });
}

PendingPurchaseEntity _pending({
  required String id,
  required String productId,
  required DateTime createdAt,
  PendingPurchaseStatus status = PendingPurchaseStatus.pending,
}) {
  return PendingPurchaseEntity(
    id: id,
    userId: 'user-1',
    productId: productId,
    purchaseToken: 'token-$id',
    contourId: null,
    status: status,
    errorMessage: null,
    createdAt: createdAt,
    resolvedAt: status == PendingPurchaseStatus.pending ? null : createdAt,
  );
}
