import '../constants/request_constants.dart';

/// Data transfer object for a user.
class UserModel {
  /// User unique identifier.
  final String id;

  /// User email address.
  final String email;

  /// User display name.
  final String name;

  /// Optional avatar URL.
  final String? avatarUrl;

  /// Whether the user permanently owns the No Ads plan.
  final bool noAdsPurchased;

  /// Creates a [UserModel].
  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    this.noAdsPurchased = false,
  });

  /// Creates a [UserModel] from a JSON map.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      noAdsPurchased: json[RequestConstants.noAdsPurchasedColumn] as bool? ?? false,
    );
  }

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'email': email,
      'name': name,
      'avatar_url': avatarUrl,
      RequestConstants.noAdsPurchasedColumn: noAdsPurchased,
    };
  }
}
