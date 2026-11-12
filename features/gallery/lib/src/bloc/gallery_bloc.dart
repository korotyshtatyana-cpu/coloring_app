import 'dart:async';

import 'package:core/core.dart';
import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';

part 'gallery_event.dart';
part 'gallery_state.dart';

/// BLoC responsible for loading and filtering gallery contours.
class GalleryBloc extends Bloc<GalleryEvent, GalleryState> {
  final GetContoursUseCase _getContoursUseCase;
  final GetUsedCategoriesUseCase _getUsedCategoriesUseCase;
  final GetContoursByIdsUseCase _getContoursByIdsUseCase;
  final ToggleFavoriteUseCase _toggleFavoriteUseCase;
  final GetFavoriteIdsUseCase _getFavoriteIdsUseCase;
  final GetWorkInProgressUseCase _getWorkInProgressUseCase;
  final GetGalleryItemsUseCase _getGalleryItemsUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final GetActiveSubscriptionUseCase _getActiveSubscriptionUseCase;
  final IsNoAdsPurchasedUseCase _isNoAdsPurchasedUseCase;
  final GetSubscriptionPlanTypeUseCase _getSubscriptionPlanTypeUseCase;
  final GetPurchaseRefundsUseCase _getPurchaseRefundsUseCase;
  final WatchRefundsUseCase _watchRefundsUseCase;
  final AdService _adService;

  int _accessRequestId = 0;
  StreamSubscription<PurchaseRefundEntity>? _refundsSubscription;

  /// Creates a [GalleryBloc] with the required use cases.
  GalleryBloc({
    required this._getContoursUseCase,
    required this._getUsedCategoriesUseCase,
    required this._getContoursByIdsUseCase,
    required this._toggleFavoriteUseCase,
    required this._getFavoriteIdsUseCase,
    required this._getWorkInProgressUseCase,
    required this._getGalleryItemsUseCase,
    required this._getCurrentUserUseCase,
    required this._getActiveSubscriptionUseCase,
    required this._isNoAdsPurchasedUseCase,
    required this._getSubscriptionPlanTypeUseCase,
    required this._getPurchaseRefundsUseCase,
    required this._watchRefundsUseCase,
    required this._adService,
  }) : super(const GalleryState()) {
    on<LoadContours>(_onLoadContours, transformer: droppable());
    on<LoadMonetizationStatus>(
      _onLoadMonetizationStatus,
      transformer: restartable(),
    );
    on<ChangeFilter>(_onChangeFilter);
    on<SelectCategory>(_onSelectCategory);
    on<ToggleFavorite>(_onToggleFavorite);
    on<OpenContour>(_onOpenContour, transformer: droppable());
    on<AccessRequestHandled>(_onAccessRequestHandled);
    _initRefundWatch();
  }

  Future<void> _onLoadContours(
    LoadContours event,
    Emitter<GalleryState> emit,
  ) async {
    try {
      emit(state.copyWith(status: GalleryStatus.loading, error: null));

      // Fetch favorites and WIP IDs only on reset (first load or filter change)
      List<String> favoriteIds = state.favoriteIds;
      List<String> workInProgressIds = state.workInProgressIds;
      Map<String, String?> workInProgressThumbnails =
          state.workInProgressThumbnails;
      List<ContourCategory> availableCategories = state.availableCategories;

      if (event.reset) {
        favoriteIds = await _getFavoriteIdsUseCase.execute();
        availableCategories = await _getUsedCategoriesUseCase.execute();
        // Entries come ordered by the date of the last change, most recent
        // first; the ids below keep that order for the WIP filter.
        final List<WorkInProgressEntity> workInProgress =
            await _getWorkInProgressUseCase.execute();
        workInProgressIds = workInProgress
            .map((WorkInProgressEntity entry) => entry.contourId)
            .toList();
        workInProgressThumbnails = <String, String?>{
          for (final WorkInProgressEntity entry in workInProgress)
            entry.contourId: entry.thumbnailPath,
        };
      }

      final List<ContourEntity> contours;
      final bool hasReachedMax;
      final int currentPage;

      if (_isCatalogFilter(state.activeFilter)) {
        final pageContours = await _getContoursUseCase.execute(
          GetContoursParams(
            limit: Constants.pageSize,
            offset: event.reset ? 0 : state.currentPage * Constants.pageSize,
            category: state.selectedCategory,
            accessType: state.activeFilter == FilterType.free
                ? ContourAccessType.free
                : null,
            onlyNew: state.activeFilter == FilterType.newArrivals,
          ),
        );
        final List<ContourEntity> combined = event.reset
            ? pageContours
            : <ContourEntity>[...state.contours, ...pageContours];

        // Catalog filters keep started projects on top; the remaining items
        // keep the repository order (created_at desc for "New").
        contours = _prioritizeWorkInProgress(combined, workInProgressIds);
        hasReachedMax = pageContours.length < Constants.pageSize;
        currentPage = event.reset ? 1 : state.currentPage + 1;
      } else {
        final targetIds = state.activeFilter == FilterType.favorites
            ? favoriteIds
            : workInProgressIds;
        final offset = event.reset ? 0 : state.currentPage * Constants.pageSize;

        if (offset >= targetIds.length) {
          contours = event.reset ? <ContourEntity>[] : state.contours;
          hasReachedMax = true;
          currentPage = state.currentPage;
        } else {
          final List<ContourEntity> pageContours =
              await _getContoursByIdsUseCase.execute(
                GetContoursByIdsParams(
                  ids: targetIds,
                  limit: Constants.pageSize,
                  offset: offset,
                  category: state.selectedCategory,
                ),
              );

          contours = event.reset
              ? pageContours
              : <ContourEntity>[...state.contours, ...pageContours];
          hasReachedMax = pageContours.length < Constants.pageSize;
          currentPage = event.reset ? 1 : state.currentPage + 1;
        }
      }

      emit(
        state.copyWith(
          status: GalleryStatus.success,
          contours: contours,
          currentPage: currentPage,
          hasReachedMax: hasReachedMax,
          error: null,
          favoriteIds: favoriteIds,
          availableCategories: availableCategories,
          workInProgressIds: workInProgressIds,
          workInProgressThumbnails: workInProgressThumbnails,
        ),
      );

      add(const LoadMonetizationStatus());
    } catch (e, stackTrace) {
      ErrorHandler.report(e, stackTrace);
      emit(state.copyWith(status: GalleryStatus.failure, error: e.toString()));
    }
  }

  Future<void> _onLoadMonetizationStatus(
    LoadMonetizationStatus event,
    Emitter<GalleryState> emit,
  ) async {
    try {
      final UserEntity? user = await _getCurrentUserUseCase.execute();
      if (user == null) {
        emit(
          state.copyWith(
            projectAccessById: const <String, ProjectAccess>{},
            showAds: false,
            clearPlanType: true,
            noAdsPurchased: false,
          ),
        );
        return;
      }

      // Fallback for a missed realtime event: this fetch feeds unacknowledged
      // refunds into the shared refund stream shown by the app-level
      // observer, and drops the subscription cache when a refund exists, so
      // the access resolution below always sees the revoked state.
      await _loadRefunds(user.id);

      final SubscriptionEntity? activeSubscription =
          await _getActiveSubscriptionUseCase.execute(user.id);
      final bool noAdsPurchased = await _isNoAdsPurchasedUseCase.execute(
        user.id,
      );
      final SubscriptionPlanType? planType = _getSubscriptionPlanTypeUseCase
          .execute(activeSubscription);
      final bool showAds =
          activeSubscription?.isActiveNow() != true && !noAdsPurchased;

      // The plan drives the avatar frame, so it must be refreshed even when
      // there are no contours to resolve access for.
      if (state.contours.isEmpty) {
        emit(
          state.copyWith(
            projectAccessById: const <String, ProjectAccess>{},
            showAds: showAds,
            planType: planType,
            clearPlanType: planType == null,
            noAdsPurchased: noAdsPurchased,
          ),
        );
        return;
      }

      final List<GalleryItemEntity> items = await _getGalleryItemsUseCase
          .execute(
            GetGalleryItemsParams(
              contours: state.contours,
              userId: user.id,
              inProgressContourIds: state.workInProgressIds.toSet(),
            ),
          );

      emit(
        state.copyWith(
          projectAccessById: <String, ProjectAccess>{
            for (final GalleryItemEntity item in items)
              item.contour.id: item.access,
          },
          showAds: showAds,
          planType: planType,
          clearPlanType: planType == null,
          noAdsPurchased: noAdsPurchased,
        ),
      );
    } catch (e, stackTrace) {
      ErrorHandler.report(e, stackTrace);
      emit(state.copyWith(status: GalleryStatus.failure, error: e.toString()));
    }
  }

  /// Triggers the refund fallback check without blocking the gallery.
  ///
  /// Access resolution must not fail just because the refund query does: on
  /// an environment where the `purchase_refunds` table is not deployed yet,
  /// the user should still see the gallery and the paywall behaviour.
  Future<void> _loadRefunds(String userId) async {
    try {
      await _getPurchaseRefundsUseCase.execute(userId);
    } catch (e, stackTrace) {
      ErrorHandler.report(e, stackTrace);
    }
  }

  /// Re-resolves access as soon as a refund is recorded, so the affected
  /// card flips to its new state without waiting for a manual refresh.
  Future<void> _initRefundWatch() async {
    try {
      final UserEntity? user = await _getCurrentUserUseCase.execute();
      if (isClosed || user == null) {
        return;
      }
      _refundsSubscription = _watchRefundsUseCase.execute(user.id).listen((_) {
        if (!isClosed) {
          add(const LoadMonetizationStatus());
        }
      });
    } catch (e, stackTrace) {
      ErrorHandler.report(e, stackTrace);
    }
  }

  @override
  Future<void> close() async {
    await _refundsSubscription?.cancel();
    return super.close();
  }

  Future<void> _onChangeFilter(
    ChangeFilter event,
    Emitter<GalleryState> emit,
  ) async {
    emit(
      state.copyWith(
        activeFilter: event.filter,
        selectedCategory: ContourCategory.all,
        currentPage: 0,
        hasReachedMax: false,
      ),
    );
    add(const LoadContours(reset: true));
  }

  Future<void> _onSelectCategory(
    SelectCategory event,
    Emitter<GalleryState> emit,
  ) async {
    emit(
      state.copyWith(
        selectedCategory: event.category,
        currentPage: 0,
        hasReachedMax: false,
      ),
    );
    add(const LoadContours(reset: true));
  }

  Future<void> _onToggleFavorite(
    ToggleFavorite event,
    Emitter<GalleryState> emit,
  ) async {
    try {
      await _toggleFavoriteUseCase.execute(event.contourId);

      final List<String> updatedFavorites = [...state.favoriteIds];
      if (updatedFavorites.contains(event.contourId)) {
        updatedFavorites.remove(event.contourId);
      } else {
        updatedFavorites.add(event.contourId);
      }

      emit(state.copyWith(favoriteIds: updatedFavorites));
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace);

      // On error, re-sync from server to ensure state consistency
      try {
        final syncedFavorites = await _getFavoriteIdsUseCase.execute();
        emit(state.copyWith(favoriteIds: syncedFavorites));
      } catch (_) {
        // If re-sync also fails, we at least showed the error dialog
      }
    }
  }

  Future<void> _onOpenContour(
    OpenContour event,
    Emitter<GalleryState> emit,
  ) async {
    final ContourEntity? contour = _findContour(event.contourId);
    final ProjectAccess? access = state.projectAccessById[event.contourId];
    if (contour == null || access == null) {
      return;
    }

    appLocator<AppLogger>().debug(
      '[Monetization] Access check: contour=${contour.id}, '
      'type=${contour.accessType.name}, result=${access.name}',
    );

    // Paid projects must go through the purchase flow, never a rewarded ad.
    if (access == ProjectAccess.locked &&
        contour.accessType == ContourAccessType.paid) {
      return;
    }

    final bool needsRewardedAd =
        access == ProjectAccess.locked &&
        contour.accessType == ContourAccessType.rewarded;

    if (!needsRewardedAd) {
      emit(
        state.copyWith(
          accessRequest: AccessRequest(
            id: ++_accessRequestId,
            contourId: event.contourId,
            granted: true,
            viewOnly: access == ProjectAccess.viewOnly,
          ),
        ),
      );
      return;
    }

    emit(state.copyWith(isLoadingAd: true));
    final RewardedAdOutcome outcome = await _adService.showRewardedAd(
      contourId: event.contourId,
    );
    emit(
      state.copyWith(
        isLoadingAd: false,
        accessRequest: AccessRequest(
          id: ++_accessRequestId,
          contourId: event.contourId,
          granted: outcome == RewardedAdOutcome.completed,
          outcome: outcome,
        ),
      ),
    );
  }

  void _onAccessRequestHandled(
    AccessRequestHandled event,
    Emitter<GalleryState> emit,
  ) {
    emit(state.copyWith(clearAccessRequest: true, isLoadingAd: false));
  }

  /// Whether [filter] pages through the catalog instead of a fixed id list.
  bool _isCatalogFilter(FilterType filter) {
    return filter == FilterType.all ||
        filter == FilterType.free ||
        filter == FilterType.newArrivals;
  }

  /// Moves started projects to the top in their last-opened order.
  ///
  /// The remaining contours keep their repository order, so a "New" query
  /// stays ordered by `created_at` desc instead of being reshuffled by an
  /// unstable sort.
  List<ContourEntity> _prioritizeWorkInProgress(
    List<ContourEntity> contours,
    List<String> workInProgressIds,
  ) {
    if (workInProgressIds.isEmpty) {
      return contours;
    }

    final Map<String, int> orderById = <String, int>{
      for (int i = 0; i < workInProgressIds.length; i++)
        workInProgressIds[i]: i,
    };
    final List<ContourEntity> started = <ContourEntity>[];
    final List<ContourEntity> rest = <ContourEntity>[];

    for (final ContourEntity contour in contours) {
      if (orderById.containsKey(contour.id)) {
        started.add(contour);
      } else {
        rest.add(contour);
      }
    }

    started.sort(
      (ContourEntity a, ContourEntity b) =>
          orderById[a.id]!.compareTo(orderById[b.id]!),
    );
    return <ContourEntity>[...started, ...rest];
  }

  ContourEntity? _findContour(String contourId) {
    for (final ContourEntity contour in state.contours) {
      if (contour.id == contourId) {
        return contour;
      }
    }
    return null;
  }
}
