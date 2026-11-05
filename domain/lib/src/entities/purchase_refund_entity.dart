import 'package:equatable/equatable.dart';

import 'subscription_plan_type.dart';

/// A purchase that was refunded by the store.
///
/// The server records one row per refunded transaction. Realtime delivery and
/// the unacknowledged-read fallback both surface the row to the app, which
/// shows the refund message once and then acknowledges it, so the user is
/// informed that the funds were returned and the purchase is no longer valid.
class PurchaseRefundEntity extends Equatable {
  /// Unique refund notification identifier.
  final String id;

  /// Store purchase token of the refunded transaction.
  final String purchaseToken;

  /// Store product identifier of the refunded purchase.
  final String productId;

  /// Moment the store reported the refund.
  final DateTime createdAt;

  /// Contour the refunded purchase unlocked, when it can be resolved.
  ///
  /// Individual project purchases encode the contour in the product id. Credit
  /// refunds resolve it best-effort from the pending purchase history, so it
  /// is `null` when the credit spend left no trace.
  final String? affectedContourId;

  /// Creates a [PurchaseRefundEntity].
  const PurchaseRefundEntity({
    required this.id,
    required this.purchaseToken,
    required this.productId,
    required this.createdAt,
    this.affectedContourId,
  });

  /// Whether the refunded purchase is a subscription plan.
  bool get isSubscriptionRefund {
    return SubscriptionPlanType.values.any(
      (SubscriptionPlanType plan) => productId.startsWith('${plan.dbValue}_'),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        purchaseToken,
        productId,
        createdAt,
        affectedContourId,
      ];
}
