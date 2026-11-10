import '../constants/request_constants.dart';
import '../utils/server_time.dart';

/// Data transfer object mirroring one paid period in `subscription_purchases`.
///
/// A subscription keeps one row in `subscriptions`, while this table keeps a
/// row per purchase or automatic renewal, which the history screen lists.
class SubscriptionPurchaseModel {
  /// Unique record identifier.
  final String id;

  /// Owner user identifier.
  final String userId;

  /// Subscription row this period belongs to, when it still exists.
  final String? subscriptionId;

  /// Platform purchase token shared by every period of the subscription.
  final String purchaseToken;

  /// Store product identifier of the plan, for example `premium`.
  final String productId;

  /// Raw plan type value, for example `no_ads`.
  final String planType;

  /// Billing period (base plan), for example `month`.
  final String? basePlanId;

  /// Google Play order identifier, when the notification carried one.
  final String? orderId;

  /// Whether the period was paid automatically by the store.
  final bool isAutoRenewal;

  /// Moment the paid period started.
  final DateTime startedAt;

  /// Moment the paid period ends.
  final DateTime? expiresAt;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Creates a [SubscriptionPurchaseModel].
  const SubscriptionPurchaseModel({
    required this.id,
    required this.userId,
    required this.subscriptionId,
    required this.purchaseToken,
    required this.productId,
    required this.planType,
    required this.basePlanId,
    required this.orderId,
    required this.isAutoRenewal,
    required this.startedAt,
    required this.expiresAt,
    required this.createdAt,
  });

  /// Creates a [SubscriptionPurchaseModel] from a JSON map.
  factory SubscriptionPurchaseModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPurchaseModel(
      id: json[RequestConstants.idColumn] as String,
      userId: json[RequestConstants.userIdColumn] as String,
      subscriptionId:
          json[RequestConstants.subscriptionIdColumn] as String?,
      purchaseToken: json[RequestConstants.purchaseTokenColumn] as String,
      productId: json[RequestConstants.productIdColumn] as String,
      planType: json[RequestConstants.planTypeColumn] as String,
      basePlanId: json[RequestConstants.basePlanIdColumn] as String?,
      orderId: json[RequestConstants.orderIdColumn] as String?,
      isAutoRenewal:
          json[RequestConstants.isAutoRenewalColumn] as bool? ?? false,
      startedAt: parseServerTimestamp(
        json[RequestConstants.startedAtColumn] as String,
      ),
      expiresAt: json[RequestConstants.expiresAtColumn] == null
          ? null
          : parseServerTimestamp(
              json[RequestConstants.expiresAtColumn] as String,
            ),
      createdAt: parseServerTimestamp(
        json[RequestConstants.createdAtColumn] as String,
      ),
    );
  }

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      RequestConstants.idColumn: id,
      RequestConstants.userIdColumn: userId,
      RequestConstants.subscriptionIdColumn: subscriptionId,
      RequestConstants.purchaseTokenColumn: purchaseToken,
      RequestConstants.productIdColumn: productId,
      RequestConstants.planTypeColumn: planType,
      RequestConstants.basePlanIdColumn: basePlanId,
      RequestConstants.orderIdColumn: orderId,
      RequestConstants.isAutoRenewalColumn: isAutoRenewal,
      RequestConstants.startedAtColumn: startedAt.toUtc().toIso8601String(),
      RequestConstants.expiresAtColumn: expiresAt?.toUtc().toIso8601String(),
      RequestConstants.createdAtColumn: createdAt.toUtc().toIso8601String(),
    };
  }
}
