import 'package:domain/domain.dart';
import '../providers/auth_remote_provider.dart';
import '../models/user_model.dart';

/// Implementation of [AuthRepository] using remote provider.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteProvider _remoteProvider;

  /// Creates a repository with the given [_remoteProvider].
  AuthRepositoryImpl({required this._remoteProvider});

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

  UserEntity _toEntity(UserModel model) {
    return UserEntity(
      id: model.id,
      email: model.email,
      name: model.name,
      avatarUrl: model.avatarUrl,
    );
  }
}
