import '../../../domain.dart';

/// Parameters for [GrantRewardedUnlockUseCase].
class GrantRewardedUnlockParams {
  /// Identifier of the user unlocking the project.
  final String userId;

  /// Identifier of the unlocked contour.
  final String contourId;

  /// Creates parameters for a rewarded unlock.
  const GrantRewardedUnlockParams({required this.userId, required this.contourId});
}

/// Grants access to a rewarded project after the video was watched to the end.
class GrantRewardedUnlockUseCase implements FutureUseCase<GrantRewardedUnlockParams, void> {
  final MonetizationRepository _repository;

  /// Creates a use case with the given [_repository].
  const GrantRewardedUnlockUseCase({required this._repository});

  @override
  Future<void> execute([GrantRewardedUnlockParams? params]) {
    if (params == null) {
      throw ArgumentError('params must not be null');
    }
    return _repository.grantRewardedUnlock(userId: params.userId, contourId: params.contourId);
  }
}
