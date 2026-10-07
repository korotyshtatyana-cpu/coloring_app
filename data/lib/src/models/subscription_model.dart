import '../constants/request_constants.dart';

/// Data transfer object mirroring the `subscriptions` table.
class SubscriptionModel {
  /// Subscription unique identifier.
  final String id;

  /// Owner user identifier.
  final String userId;

  /// Store product identifier.
  final String productId;

  /// Raw plan type value, for example `no_ads`.
  final String planType;

  /// Whether the subscription is active.
  final bool isActive;

  /// Moment the subscription started.
  final DateTime startedAt;

  /// Moment the subscription expires.
  final DateTime expiresAt;

  /// Platform purchase token.
  final String? purchaseToken;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Last update timestamp.
  final DateTime? updatedAt;

  /// Creates a [SubscriptionModel].
  const SubscriptionModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.planType,
    required this.isActive,
    required this.startedAt,
    required this.expiresAt,
    required this.purchaseToken,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a [SubscriptionModel] from a JSON map.
  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json[RequestConstants.idColumn] as String,
      userId: json[RequestConstants.userIdColumn] as String,
      productId: json[RequestConstants.productIdColumn] as String,
      planType: json[RequestConstants.planTypeColumn] as String,
      isActive: json[RequestConstants.isActiveColumn] as bool? ?? false,
      startedAt: DateTime.parse(json[RequestConstants.startedAtColumn] as String),
      expiresAt: DateTime.parse(json[RequestConstants.expiresAtColumn] as String),
      purchaseToken: json[RequestConstants.purchaseTokenColumn] as String?,
      createdAt: DateTime.parse(json[RequestConstants.createdAtColumn] as String),
      updatedAt: json[RequestConstants.updatedAtColumn] == null
          ? null
          : DateTime.parse(json[RequestConstants.updatedAtColumn] as String),
    );
  }

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      RequestConstants.idColumn: id,
      RequestConstants.userIdColumn: userId,
      RequestConstants.productIdColumn: productId,
      RequestConstants.planTypeColumn: planType,
      RequestConstants.isActiveColumn: isActive,
      RequestConstants.startedAtColumn: startedAt.toIso8601String(),
      RequestConstants.expiresAtColumn: expiresAt.toIso8601String(),
      RequestConstants.purchaseTokenColumn: purchaseToken,
      RequestConstants.createdAtColumn: createdAt.toIso8601String(),
      RequestConstants.updatedAtColumn: updatedAt?.toIso8601String(),
    };
  }
}
