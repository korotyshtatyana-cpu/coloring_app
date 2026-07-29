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

  /// Creates a [UserModel].
  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
  });

  /// Creates a [UserModel] from a JSON map.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'email': email,
      'name': name,
      'avatar_url': avatarUrl,
    };
  }
}
