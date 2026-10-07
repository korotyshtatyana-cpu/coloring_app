import 'package:domain/domain.dart';

import '../models/user_entitlement_model.dart';

/// Maps between [UserEntitlementModel] and [UserEntitlementEntity].
abstract final class UserEntitlementMapper {
  /// Converts a model to an entity, mapping the raw type string to
  /// [EntitlementType].
  ///
  /// Records with an unrecognized type are skipped by returning `null`, so a
  /// new server-side type never grants access by accident.
  static UserEntitlementEntity? toEntity(UserEntitlementModel model) {
    final EntitlementType? type = _toEntitlementType(model.type);
    if (type == null) {
      return null;
    }

    return UserEntitlementEntity(
      id: model.id,
      userId: model.userId,
      contourId: model.contourId,
      type: type,
      grantedAt: model.grantedAt,
      expiresAt: model.expiresAt,
      purchaseToken: model.purchaseToken,
    );
  }

  /// Converts an entity to a model, writing the type as its database string.
  static UserEntitlementModel toModel(UserEntitlementEntity entity) {
    return UserEntitlementModel(
      id: entity.id,
      userId: entity.userId,
      contourId: entity.contourId,
      type: entity.type.dbValue,
      grantedAt: entity.grantedAt,
      expiresAt: entity.expiresAt,
      purchaseToken: entity.purchaseToken,
    );
  }

  /// Maps the database type string to the domain enum, or `null` when unknown.
  static EntitlementType? _toEntitlementType(String value) {
    return switch (value) {
      'purchase' => EntitlementType.purchase,
      'rewarded_unlock' => EntitlementType.rewardedUnlock,
      'subscription_access' => EntitlementType.subscriptionAccess,
      _ => null,
    };
  }
}
