import '../entities/user_entity.dart';

/// Repository for authentication operations.
abstract class AuthRepository {
  /// Checks whether the user is currently authenticated.
  Future<bool> checkAuth();

  /// Signs the user in and returns the authenticated [UserEntity].
  Future<UserEntity> signIn();

  /// Attempts to sign the user in silently using a platform account.
  /// Throws if silent sign-in is not available.
  Future<UserEntity> signInSilently();
}
