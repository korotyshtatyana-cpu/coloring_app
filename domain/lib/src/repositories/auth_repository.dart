import '../entities/user_entity.dart';

/// Repository for authentication operations.
abstract class AuthRepository {
  /// Checks whether the user is currently authenticated.
  Future<bool> checkAuth();

  /// Returns the currently authenticated user from the active session,
  /// or `null` when there is no session.
  Future<UserEntity?> getCurrentUser();

  /// Signs the user in and returns the authenticated [UserEntity].
  Future<UserEntity> signIn();

  /// Attempts to sign the user in silently using a platform account.
  /// Throws if silent sign-in is not available.
  Future<UserEntity> signInSilently();
}
