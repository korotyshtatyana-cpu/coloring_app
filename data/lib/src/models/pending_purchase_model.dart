import '../constants/request_constants.dart';

/// Data transfer object mirroring the `pending_purchases` table.
class PendingPurchaseModel {
  /// Pending purchase unique identifier.
  final String id;

  /// Purchasing user identifier.
  final String userId;

  /// Store product identifier.
  final String productId;

  /// Platform purchase token, when the store returned one.
  final String? purchaseToken;

  /// Raw status value, for example `pending`.
  final String status;

  /// Failure reason, when the status is `failed`.
  final String? errorMessage;

  /// Moment the purchase was queued.
  final DateTime createdAt;

  /// Moment the purchase was confirmed or rejected.
  final DateTime? resolvedAt;

  /// Creates a [PendingPurchaseModel].
  const PendingPurchaseModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.purchaseToken,
    required this.status,
    required this.errorMessage,
    required this.createdAt,
    required this.resolvedAt,
  });

  /// Creates a [PendingPurchaseModel] from a JSON map.
  factory PendingPurchaseModel.fromJson(Map<String, dynamic> json) {
    return PendingPurchaseModel(
      id: json[RequestConstants.idColumn] as String,
      userId: json[RequestConstants.userIdColumn] as String,
      productId: json[RequestConstants.productIdColumn] as String,
      purchaseToken: json[RequestConstants.purchaseTokenColumn] as String?,
      status: json[RequestConstants.statusColumn] as String,
      errorMessage: json[RequestConstants.errorMessageColumn] as String?,
      createdAt: DateTime.parse(json[RequestConstants.createdAtColumn] as String),
      resolvedAt: json[RequestConstants.resolvedAtColumn] == null
          ? null
          : DateTime.parse(json[RequestConstants.resolvedAtColumn] as String),
    );
  }

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      RequestConstants.idColumn: id,
      RequestConstants.userIdColumn: userId,
      RequestConstants.productIdColumn: productId,
      RequestConstants.purchaseTokenColumn: purchaseToken,
      RequestConstants.statusColumn: status,
      RequestConstants.errorMessageColumn: errorMessage,
      RequestConstants.createdAtColumn: createdAt.toIso8601String(),
      RequestConstants.resolvedAtColumn: resolvedAt?.toIso8601String(),
    };
  }
}
