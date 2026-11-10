import '../constants/request_constants.dart';
import '../utils/server_time.dart';

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

  /// Billing period (base plan) of the subscription, for example `month`.
  final String? basePlanId;

  /// Whether the subscription is active.
  final bool isActive;

  /// Whether Google Play will renew the subscription automatically.
  ///
  /// `false` after the user cancels auto-renew, while [expiresAt] still
  /// grants access until the paid period ends.
  final bool isAutoRenew;

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
    this.basePlanId,
    this.isAutoRenew = true,
  });

  /// Creates a [SubscriptionModel] from a JSON map.
  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json[RequestConstants.idColumn] as String,
      userId: json[RequestConstants.userIdColumn] as String,
      productId: json[RequestConstants.productIdColumn] as String,
      planType: json[RequestConstants.planTypeColumn] as String,
      basePlanId: json[RequestConstants.basePlanIdColumn] as String?,
      isActive: json[RequestConstants.isActiveColumn] as bool? ?? false,
      isAutoRenew: json[RequestConstants.isAutoRenewColumn] as bool? ?? true,
      startedAt: parseServerTimestamp(
        json[RequestConstants.startedAtColumn] as String,
      ),
      expiresAt: parseServerTimestamp(
        json[RequestConstants.expiresAtColumn] as String,
      ),
      purchaseToken: json[RequestConstants.purchaseTokenColumn] as String?,
      createdAt: parseServerTimestamp(
        json[RequestConstants.createdAtColumn] as String,
      ),
      updatedAt: json[RequestConstants.updatedAtColumn] == null
          ? null
          : parseServerTimestamp(
              json[RequestConstants.updatedAtColumn] as String,
            ),
    );
  }

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      RequestConstants.idColumn: id,
      RequestConstants.userIdColumn: userId,
      RequestConstants.productIdColumn: productId,
      RequestConstants.planTypeColumn: planType,
      RequestConstants.basePlanIdColumn: basePlanId,
      RequestConstants.isActiveColumn: isActive,
      RequestConstants.isAutoRenewColumn: isAutoRenew,
      RequestConstants.startedAtColumn: startedAt.toUtc().toIso8601String(),
      RequestConstants.expiresAtColumn: expiresAt.toUtc().toIso8601String(),
      RequestConstants.purchaseTokenColumn: purchaseToken,
      RequestConstants.createdAtColumn: createdAt.toUtc().toIso8601String(),
      RequestConstants.updatedAtColumn: updatedAt?.toUtc().toIso8601String(),
    };
  }
}
