import 'package:domain/domain.dart';

import '../models/pending_purchase_model.dart';

/// Maps between [PendingPurchaseModel] and [PendingPurchaseEntity].
abstract final class PendingPurchaseMapper {
  /// Converts a model to an entity, mapping the raw status string to
  /// [PendingPurchaseStatus].
  static PendingPurchaseEntity toEntity(PendingPurchaseModel model) {
    return PendingPurchaseEntity(
      id: model.id,
      userId: model.userId,
      productId: model.productId,
      purchaseToken: model.purchaseToken,
      status: _toStatus(model.status),
      errorMessage: model.errorMessage,
      createdAt: model.createdAt,
      resolvedAt: model.resolvedAt,
    );
  }

  /// Converts an entity to a model, writing the status as its database string.
  static PendingPurchaseModel toModel(PendingPurchaseEntity entity) {
    return PendingPurchaseModel(
      id: entity.id,
      userId: entity.userId,
      productId: entity.productId,
      purchaseToken: entity.purchaseToken,
      status: entity.status.dbValue,
      errorMessage: entity.errorMessage,
      createdAt: entity.createdAt,
      resolvedAt: entity.resolvedAt,
    );
  }

  /// Maps the database status string to the domain enum.
  ///
  /// Unknown values fall back to [PendingPurchaseStatus.pending] so the
  /// purchase is retried rather than dropped.
  static PendingPurchaseStatus _toStatus(String value) {
    return switch (value) {
      'pending' => PendingPurchaseStatus.pending,
      'resolved' => PendingPurchaseStatus.resolved,
      'failed' => PendingPurchaseStatus.failed,
      _ => PendingPurchaseStatus.pending,
    };
  }
}
