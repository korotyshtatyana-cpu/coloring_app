import '../../../domain.dart';

/// Parameters for [GetGalleryItemsUseCase].
class GetGalleryItemsParams {
  /// Contours to resolve access for, typically the current gallery page.
  final List<ContourEntity> contours;

  /// Identifier of the user the access is resolved for.
  final String userId;

  /// Identifiers of contours the user already has strokes saved for.
  ///
  /// Contours in this set become [ProjectAccess.viewOnly] for users whose
  /// Premium subscription has expired, instead of being fully locked.
  final Set<String> inProgressContourIds;

  /// Creates parameters for a gallery access resolution.
  const GetGalleryItemsParams({
    required this.contours,
    required this.userId,
    this.inProgressContourIds = const <String>{},
  });
}

/// Resolves access for a whole page of contours in one batch.
///
/// Subscription, plan and entitlement state is fetched once for the entire page
/// and then applied to every contour. The gallery calls this together with
/// [GetContoursUseCase] and [GetWorkInProgressUseCase], so the in-progress flag
/// displayed on a card comes from the same data the access decision uses.
///
/// Throws when the server is unreachable: access is never resolved from cached
/// or locally stored state.
class GetGalleryItemsUseCase
    implements FutureUseCase<GetGalleryItemsParams, List<GalleryItemEntity>> {
  final MonetizationRepository _repository;

  /// Creates a use case with the given [_repository].
  const GetGalleryItemsUseCase({required MonetizationRepository repository})
      : _repository = repository;

  @override
  Future<List<GalleryItemEntity>> execute([GetGalleryItemsParams? params]) {
    if (params == null) {
      throw ArgumentError('params must not be null');
    }

    final GetGalleryItemsParams p = params;
    if (p.contours.isEmpty) {
      return Future<List<GalleryItemEntity>>.value(
        const <GalleryItemEntity>[],
      );
    }

    return Future.wait<Object?>(<Future<Object?>>[
      _repository.getActiveSubscription(p.userId),
      _repository.isNoAdsPurchased(p.userId),
      _repository.getAllEntitlements(p.userId),
    ]).then((List<Object?> values) {
      final SubscriptionEntity? subscription =
          values[0] as SubscriptionEntity?;
      final bool noAdsPurchased = values[1] as bool? ?? false;
      final List<UserEntitlementEntity> entitlements =
          values[2] as List<UserEntitlementEntity>? ?? const [];

      final Map<String, UserEntitlementEntity> byContourId =
          <String, UserEntitlementEntity>{
        for (final UserEntitlementEntity e in entitlements) e.contourId: e,
      };

      return p.contours
          .map(
            (ContourEntity contour) => GalleryItemEntity(
              contour: contour,
              access: ProjectAccessCalculator.calculate(
                contour: contour,
                activeSubscription: subscription,
                noAdsPurchased: noAdsPurchased,
                entitlement: byContourId[contour.id],
                hasProgress: p.inProgressContourIds.contains(contour.id),
              ),
            ),
          )
          .toList(growable: false);
    });
  }
}