import 'package:equatable/equatable.dart';

/// Outcome of a store purchase or restore operation.
enum PurchaseUpdateStatus {
  /// The purchase was verified and the entitlement was granted.
  success,

  /// The store has not confirmed the purchase yet.
  pending,

  /// The purchase or verification failed.
  failed,

  /// The user closed the store purchase flow without completing it.
  canceled,

  /// A restore completed without finding any purchases.
  empty,
}

/// Result of a single purchase or restore operation.
///
/// Emitted by the billing service so the presentation layer can show the
/// matching feedback and refresh the access state.
class PurchaseUpdateEntity extends Equatable {
  /// Outcome of the operation.
  final PurchaseUpdateStatus status;

  /// Store product identifier the update belongs to, when known.
  final String? productId;

  /// Contour identifier for project purchases, when known.
  final String? contourId;

  /// Whether the update originates from a restore request.
  final bool isRestore;

  /// Human readable error message for [PurchaseUpdateStatus.failed].
  final String? error;

  /// Creates a [PurchaseUpdateEntity].
  const PurchaseUpdateEntity({
    required this.status,
    this.productId,
    this.contourId,
    this.isRestore = false,
    this.error,
  });

  @override
  List<Object?> get props => <Object?>[
    status,
    productId,
    contourId,
    isRestore,
    error,
  ];
}
