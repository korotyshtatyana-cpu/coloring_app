import 'package:equatable/equatable.dart';

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

  /// Current confirmation status.
  final PendingPurchaseStatus status;

  /// Failure reason, when [status] is [PendingPurchaseStatus.failed].
  final String? errorMessage;

  /// Moment the purchase was queued.
  final DateTime createdAt;

  /// Moment the purchase was confirmed or rejected.
  final DateTime? resolvedAt;

  /// Creates a [PendingPurchaseEntity].
  const PendingPurchaseEntity({
    required this.id,
    required this.userId,
    required this.productId,
    required this.purchaseToken,
    required this.status,
    required this.errorMessage,
    required this.createdAt,
    required this.resolvedAt,
  });

  @override
  List<Object?> get props => <Object?>[
    id,
    userId,
    productId,
    purchaseToken,
    status,
    errorMessage,
    createdAt,
    resolvedAt,
  ];
}
