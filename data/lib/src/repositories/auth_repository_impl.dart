import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

import '../providers/auth_remote_provider.dart';
import '../providers/canvas_local_provider.dart';
import '../models/user_model.dart';

/// Implementation of [AuthRepository] using remote provider.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteProvider _remoteProvider;
  final CanvasLocalProvider _localProvider;

  /// Creates a repository with the given [_remoteProvider] and
  /// [_localProvider].
  AuthRepositoryImpl({
    required this._remoteProvider,
    required this._localProvider,
  });

  @override
  Future<bool> checkAuth() {
    return _remoteProvider.checkAuth();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final UserModel? model = _remoteProvider.getCurrentUser();
    return model == null ? null : _toEntity(model);
  }

  @override
  Future<UserEntity> signIn() async {
    final UserModel model = await _remoteProvider.signIn();
    return _toEntity(model);
  }

  @override
  Future<UserEntity> signInSilently() async {
    final UserModel model = await _remoteProvider.signInSilently();
    return _toEntity(model);
  }

  @override
  Future<void> deleteAccount() async {
    await _remoteProvider.deleteAccount();
    try {
      await _localProvider.clearUserData();
    } catch (e, stackTrace) {
      // The account is already deleted remotely, so a local cleanup
      // failure must not surface as an account deletion error.
      debugPrint('Local user data cleanup failed: $e');
      debugPrint('$stackTrace');
    }
  }

  UserEntity _toEntity(UserModel model) {
    return UserEntity(
      id: model.id,
      email: model.email,
      name: model.name,
      avatarUrl: model.avatarUrl,
    );
  }
}
