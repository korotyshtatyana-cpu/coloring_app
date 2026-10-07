import '../../../domain.dart';

/// Parameters for [GetEntitlementUseCase].
class GetEntitlementParams {
  /// Identifier of the user the entitlement belongs to.
  final String userId;

  /// Identifier of the contour the entitlement is checked for.
  final String contourId;

  /// Creates parameters for an entitlement lookup.
  const GetEntitlementParams({required this.userId, required this.contourId});
}

/// Returns the user's entitlement for a single project.
///
/// Returns `null` when the user has no entitlement for the project.
///
/// Prefer [GetGalleryItemsUseCase] when access is needed for a list of
/// projects: it resolves the whole page in a single batch.
class GetEntitlementUseCase implements FutureUseCase<GetEntitlementParams, UserEntitlementEntity?> {
  final MonetizationRepository _repository;

  /// Creates a use case with the given [_repository].
  const GetEntitlementUseCase({required this._repository});

  @override
  Future<UserEntitlementEntity?> execute([GetEntitlementParams? params]) {
    if (params == null) {
      throw ArgumentError('params must not be null');
    }
    return _repository.getEntitlement(userId: params.userId, contourId: params.contourId);
  }
}
