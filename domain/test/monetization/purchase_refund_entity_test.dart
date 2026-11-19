import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  PurchaseRefundEntity refund(String productId) => PurchaseRefundEntity(
    id: 'id',
    purchaseToken: 'token',
    productId: productId,
    createdAt: DateTime(2026, 1, 1),
  );

  group('PurchaseRefundEntity.isSubscriptionRefund', () {
    test('is true for subscription products', () {
      expect(refund('premium').isSubscriptionRefund, isTrue);
      expect(refund('no_ads').isSubscriptionRefund, isTrue);
    });

    test('is false for one-time products', () {
      expect(refund('unlock_credit').isSubscriptionRefund, isFalse);
      expect(refund('contour_123').isSubscriptionRefund, isFalse);
    });
  });
}
