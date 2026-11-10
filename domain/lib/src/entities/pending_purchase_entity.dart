import 'package:equatable/equatable.dart';

import 'subscription_interval.dart';
import 'subscription_plan_type.dart';

/// Status of a queued purchase awaiting confirmation.
enum PendingPurchaseStatus {
  /// Waiting to be verified against Google Play Billing.
  pending('pending'),

  /// Confirmed: access was granted.
  resolved('resolved'),

  /// Rejected by the store.
  failed('failed');

  /// Value stored in the database `pending_purchases.status` column.
  final String dbValue;

  const PendingPurchaseStatus(this.dbValue);

  /// Returns the status matching the given database [value].
  ///
  /// Falls back to [PendingPurchaseStatus.pending], so an unrecognized record is
  /// retried rather than silently dropped.
  static PendingPurchaseStatus fromDb(String value) {
    for (final PendingPurchaseStatus status in PendingPurchaseStatus.values) {
      if (status.dbValue == value) {
        return status;
      }
    }
    return PendingPurchaseStatus.pending;
  }
}

/// Result of re-checking a queued purchase with the store.
enum PendingPurchaseRefreshStatus {
  /// The store confirmed the purchase and the entitlement was granted.
  verified,

  /// The store still has not finalized the payment.
  pending,

  /// The store rejected or canceled the payment.
  failed,
}

/// Domain entity representing a purchase awaiting store confirmation.
class PendingPurchaseEntity extends Equatable {
  /// Unique pending purchase identifier.
  final String id;

  /// Identifier of the purchasing user.
  final String userId;

  /// Store product identifier.
  final String productId;

  /// Platform purchase token, when the store already returned one.
  final String? purchaseToken;

  /// Contour the purchase unlocks, when it is a project purchase.
  final String? contourId;

  /// Title of the purchased contour, when known.
  final String? contourTitle;

  /// Preview image URL of the purchased contour, when known.
  final String? contourPreviewUrl;

  /// Billing period of a subscription purchase, when known.
  final SubscriptionInterval? subscriptionInterval;

  /// Whether a subscription period was paid automatically by the store.
  final bool isAutoRenewal;

  /// Current confirmation status.
  final PendingPurchaseStatus status;

  /// Failure reason, when [status] is [PendingPurchaseStatus.failed].
  final String? errorMessage;

  /// Moment the purchase was queued.
  final DateTime createdAt;

  /// Moment the purchase was confirmed or rejected.
  final DateTime? resolvedAt;

  /// Whether this purchase belongs to a subscription rather than a one-time
  /// project purchase.
  bool get isSubscription =>
      productId == SubscriptionPlanType.noAds.dbValue ||
      productId == SubscriptionPlanType.premium.dbValue;

  /// Creates a [PendingPurchaseEntity].
  const PendingPurchaseEntity({
    required this.id,
    required this.userId,
    required this.productId,
    required this.purchaseToken,
    required this.contourId,
    required this.status,
    required this.errorMessage,
    required this.createdAt,
    required this.resolvedAt,
    this.contourTitle,
    this.contourPreviewUrl,
    this.subscriptionInterval,
    this.isAutoRenewal = false,
  });

  @override
  List<Object?> get props => <Object?>[
    id,
    userId,
    productId,
    purchaseToken,
    contourId,
    contourTitle,
    contourPreviewUrl,
    subscriptionInterval,
    isAutoRenewal,
    status,
    errorMessage,
    createdAt,
    resolvedAt,
  ];
}
