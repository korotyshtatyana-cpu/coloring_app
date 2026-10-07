import 'package:domain/domain.dart';

import '../models/subscription_model.dart';

/// Maps between [SubscriptionModel] and [SubscriptionEntity].
abstract final class SubscriptionMapper {
  /// Converts a model to an entity, mapping the raw plan type string to
  /// [SubscriptionPlanType].
  static SubscriptionEntity toEntity(SubscriptionModel model) {
    return SubscriptionEntity(
      id: model.id,
      userId: model.userId,
      productId: model.productId,
      planType: _toPlanType(model.planType),
      isActive: model.isActive,
      startedAt: model.startedAt,
      expiresAt: model.expiresAt,
      purchaseToken: model.purchaseToken,
    );
  }

  /// Converts an entity to a model, writing the plan type as its database
  /// string.
  static SubscriptionModel toModel(SubscriptionEntity entity) {
    return SubscriptionModel(
      id: entity.id,
      userId: entity.userId,
      productId: entity.productId,
      planType: entity.planType.dbValue,
      isActive: entity.isActive,
      startedAt: entity.startedAt,
      expiresAt: entity.expiresAt,
      purchaseToken: entity.purchaseToken,
      createdAt: entity.startedAt,
      updatedAt: null,
    );
  }

  /// Maps the database plan type string to the domain enum.
  ///
  /// Unknown values fall back to [SubscriptionPlanType.premium], so an
  /// unrecognized plan grants the wider access instead of locking content.
  static SubscriptionPlanType _toPlanType(String value) {
    return switch (value) {
      'no_ads' => SubscriptionPlanType.noAds,
      'premium' => SubscriptionPlanType.premium,
      _ => SubscriptionPlanType.premium,
    };
  }
}
