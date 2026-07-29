import 'package:equatable/equatable.dart';

/// Domain entity representing an authenticated user.
class UserEntity extends Equatable {
  /// Unique user identifier.
  final String id;

  /// User email address.
  final String email;

  /// User display name.
  final String name;

  /// Optional URL to the user's avatar image.
  final String? avatarUrl;

  /// Creates a [UserEntity].
  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
  });

  @override
  List<Object?> get props => <Object?>[id, email, name, avatarUrl];
}
