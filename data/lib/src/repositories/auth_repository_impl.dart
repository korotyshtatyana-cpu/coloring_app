// ignore_for_file: prefer_initializing_formals

import 'package:core/core.dart';
import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../providers/auth_remote_provider.dart';
import '../providers/canvas_local_provider.dart';

/// Implementation of [AuthRepository] using remote provider.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteProvider _remoteProvider;
  final CanvasLocalProvider _localProvider;

  /// Creates a repository with given [remoteProvider] and [localProvider].
  AuthRepositoryImpl({
    required AuthRemoteProvider remoteProvider,
    required CanvasLocalProvider localProvider,
  })  : _remoteProvider = remoteProvider,
        _localProvider = localProvider;

  @override
  Future<bool> checkAuth() {
    return _remoteProvider.checkAuth();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final UserModel? model = _remoteProvider.getCurrentUser();
    final UserEntity? entity = model == null ? null : _toEntity(model);
    appLocator<CrashReporter>().setUserId(entity?.id);
    return entity;
  }

  @override
  Future<UserEntity> signIn() async {
    try {
      final UserModel model = await _remoteProvider.signIn();
      final UserEntity entity = _toEntity(model);
      appLocator<CrashReporter>().setUserId(entity.id);
      return entity;
    } catch (_) {
      appLocator<CrashReporter>().setUserId(null);
      rethrow;
    }
  }

  @override
  Future<UserEntity> signInSilently() async {
    try {
      final UserModel model = await _remoteProvider.signInSilently();
      final UserEntity entity = _toEntity(model);
      appLocator<CrashReporter>().setUserId(entity.id);
      return entity;
    } catch (_) {
      appLocator<CrashReporter>().setUserId(null);
      rethrow;
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await _remoteProvider.deleteAccount();
    } finally {
      appLocator<CrashReporter>().setUserId(null);
    }
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
