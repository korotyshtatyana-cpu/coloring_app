import '../constants/request_constants.dart';
import '../utils/server_time.dart';

/// Data transfer object mirroring the `user_entitlements` table.
class UserEntitlementModel {
  /// Entitlement unique identifier.
  final String id;

  /// User the entitlement belongs to.
  final String userId;

  /// Unlocked contour identifier.
  final String contourId;

  /// Raw entitlement type value, for example `rewarded_unlock`.
  final String type;

  /// Moment the entitlement was granted.
  final DateTime grantedAt;

  /// Moment the entitlement stops being valid, `null` when permanent.
  final DateTime? expiresAt;

  /// Platform purchase token backing the entitlement.
  final String? purchaseToken;

  /// Title of the unlocked contour, when the query embeds it.
  final String? contourTitle;

  /// Preview image URL of the unlocked contour, when the query embeds it.
  final String? contourPreviewUrl;

  /// Creates a [UserEntitlementModel].
  const UserEntitlementModel({
    required this.id,
    required this.userId,
    required this.contourId,
    required this.type,
    required this.grantedAt,
    required this.expiresAt,
    required this.purchaseToken,
    this.contourTitle,
    this.contourPreviewUrl,
  });

  /// Creates a [UserEntitlementModel] from a JSON map.
  factory UserEntitlementModel.fromJson(Map<String, dynamic> json) {
    final Object? contour = json[RequestConstants.contoursTable];
    final Map<String, dynamic>? contourJson = switch (contour) {
      final Map<String, dynamic> map => map,
      final List<dynamic> list when list.isNotEmpty =>
        list.first as Map<String, dynamic>,
      _ => null,
    };

    return UserEntitlementModel(
      id: json[RequestConstants.idColumn] as String,
      userId: json[RequestConstants.userIdColumn] as String,
      contourId: json[RequestConstants.contourIdColumn] as String,
      type: json[RequestConstants.typeColumn] as String,
      grantedAt: parseServerTimestamp(
        json[RequestConstants.grantedAtColumn] as String,
      ),
      expiresAt: json[RequestConstants.expiresAtColumn] == null
          ? null
          : parseServerTimestamp(
              json[RequestConstants.expiresAtColumn] as String,
            ),
      purchaseToken: json[RequestConstants.purchaseTokenColumn] as String?,
      contourTitle: contourJson?[RequestConstants.titleColumn] as String?,
      contourPreviewUrl:
          contourJson?[RequestConstants.previewUrlColumn] as String?,
    );
  }

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      RequestConstants.idColumn: id,
      RequestConstants.userIdColumn: userId,
      RequestConstants.contourIdColumn: contourId,
      RequestConstants.typeColumn: type,
      RequestConstants.grantedAtColumn: grantedAt.toUtc().toIso8601String(),
      RequestConstants.expiresAtColumn: expiresAt?.toUtc().toIso8601String(),
      RequestConstants.purchaseTokenColumn: purchaseToken,
    };
  }
}
