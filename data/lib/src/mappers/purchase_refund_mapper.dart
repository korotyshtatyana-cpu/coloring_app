import 'package:domain/domain.dart';

import '../models/purchase_refund_model.dart';

/// Maps between [PurchaseRefundModel] and [PurchaseRefundEntity].
abstract final class PurchaseRefundMapper {
  /// Converts a model to a domain entity.
  ///
  /// [affectedContourId] is resolved by the repository, not stored in the
  /// row, so it is passed separately.
  static PurchaseRefundEntity toEntity(
    PurchaseRefundModel model, {
    String? affectedContourId,
  }) {
    return PurchaseRefundEntity(
      id: model.id,
      purchaseToken: model.purchaseToken,
      productId: model.productId,
      createdAt: model.createdAt,
      affectedContourId: affectedContourId,
    );
  }
}
