import 'package:equatable/equatable.dart';

import 'entitlement_type.dart';

/// Domain entity representing access granted to a user for a single project.
class UserEntitlementEntity extends Equatable {
  /// Unique entitlement identifier.
  final String id;

  /// Identifier of the user the entitlement belongs to.
  final String userId;

  /// Identifier of the unlocked contour.
  final String contourId;

  /// Reason the entitlement was granted.
  final EntitlementType type;

  /// Moment the entitlement was granted.
  final DateTime grantedAt;

  /// Moment the entitlement stops being valid, `null` when permanent.
  final DateTime? expiresAt;

  /// Platform purchase token backing the entitlement.
  final String? purchaseToken;

  /// Creates a [UserEntitlementEntity].
  const UserEntitlementEntity({
    required this.id,
    required this.userId,
    required this.contourId,
    required this.type,
    required this.grantedAt,
    this.expiresAt,
    this.purchaseToken,
  });

  /// Whether the entitlement never expires.
  bool get isPermanent => expiresAt == null;

  /// Whether the entitlement is valid at the given moment.
  bool isActive([DateTime? now]) {
    if (expiresAt == null) {
      return true;
    }
    return !(now ?? DateTime.now()).isAfter(expiresAt!);
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    userId,
    contourId,
    type,
    grantedAt,
    expiresAt,
    purchaseToken,
  ];
}
