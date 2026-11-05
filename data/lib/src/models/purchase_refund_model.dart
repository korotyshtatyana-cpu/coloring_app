import '../constants/request_constants.dart';

/// Data transfer object mirroring the `purchase_refunds` table.
class PurchaseRefundModel {
  /// Refund notification unique identifier.
  final String id;

  /// Identifier of the user who made the refunded purchase.
  final String userId;

  /// Store purchase token of the refunded transaction.
  final String purchaseToken;

  /// Store product identifier.
  final String productId;

  /// Moment the refund was recorded.
  final DateTime createdAt;

  /// Moment the user saw the refund message, if any.
  final DateTime? acknowledgedAt;

  /// Creates a [PurchaseRefundModel].
  const PurchaseRefundModel({
    required this.id,
    required this.userId,
    required this.purchaseToken,
    required this.productId,
    required this.createdAt,
    required this.acknowledgedAt,
  });

  /// Creates a [PurchaseRefundModel] from a JSON map.
  factory PurchaseRefundModel.fromJson(Map<String, dynamic> json) {
    return PurchaseRefundModel(
      id: json[RequestConstants.idColumn] as String,
      userId: json[RequestConstants.userIdColumn] as String,
      purchaseToken: json[RequestConstants.purchaseTokenColumn] as String,
      productId: json[RequestConstants.productIdColumn] as String,
      createdAt: DateTime.parse(
        json[RequestConstants.createdAtColumn] as String,
      ),
      acknowledgedAt: json[RequestConstants.acknowledgedAtColumn] == null
          ? null
          : DateTime.parse(
              json[RequestConstants.acknowledgedAtColumn] as String,
            ),
    );
  }

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      RequestConstants.idColumn: id,
      RequestConstants.userIdColumn: userId,
      RequestConstants.purchaseTokenColumn: purchaseToken,
      RequestConstants.productIdColumn: productId,
      RequestConstants.createdAtColumn: createdAt.toIso8601String(),
      RequestConstants.acknowledgedAtColumn:
          acknowledgedAt?.toIso8601String(),
    };
  }
}
