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
    required this._getPurchaseRefundsUseCase,
    required this._watchRefundsUseCase,
    required this._adService,
  }) : super(const GalleryState()) {
    on<LoadContours>(_onLoadContours, transformer: droppable());
    on<LoadMonetizationStatus>(_onLoadMonetizationStatus, transformer: restartable());
    on<ChangeFilter>(_onChangeFilter);
    on<SelectCategory>(_onSelectCategory);
    on<ToggleFavorite>(_onToggleFavorite);
    on<OpenContour>(_onOpenContour, transformer: droppable());
    on<AccessRequestHandled>(_onAccessRequestHandled);
    _initRefundWatch();
  }

  Future<void> _onLoadContours(LoadContours event, Emitter<GalleryState> emit) async {
    try {
      emit(state.copyWith(status: GalleryStatus.loading, error: null));

      // Fetch favorites and WIP IDs only on reset (first load or filter change)
      List<String> favoriteIds = state.favoriteIds;
      List<String> workInProgressIds = state.workInProgressIds;
      Map<String, String?> workInProgressThumbnails = state.workInProgressThumbnails;
      List<ContourCategory> availableCategories = state.availableCategories;

      if (event.reset) {
        favoriteIds = await _getFavoriteIdsUseCase.execute();
        availableCategories = await _getUsedCategoriesUseCase.execute();
        // Entries come ordered by the date of the last change, most recent
        // first; the ids below keep that order for the WIP filter.
        final List<WorkInProgressEntity> workInProgress = await _getWorkInProgressUseCase.execute();
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

      if (state.activeFilter == FilterType.all) {
        final pageContours = await _getContoursUseCase.execute(
          GetContoursParams(
            limit: Constants.pageSize,
            offset: event.reset ? 0 : state.currentPage * Constants.pageSize,
            category: state.selectedCategory,
          ),
        );
        final List<ContourEntity> combined = event.reset
            ? pageContours
            : <ContourEntity>[...state.contours, ...pageContours];

        // Prioritize WIP items at the top of the "All" list
        if (workInProgressIds.isNotEmpty) {
          combined.sort((a, b) {
            final aIndex = workInProgressIds.indexOf(a.id);
            final bIndex = workInProgressIds.indexOf(b.id);

            // Both are WIP: follow last_opened order (stored in workInProgressIds)
            if (aIndex != -1 && bIndex != -1) return aIndex.compareTo(bIndex);
            // Only A is WIP: A goes first
            if (aIndex != -1) return -1;
            // Only B is WIP: B goes first
            if (bIndex != -1) return 1;

            // Neither is WIP: keep default repository order (usually created_at desc)
            return 0;
          });
        }

        contours = combined;
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
          final List<ContourEntity> pageContours = await _getContoursByIdsUseCase.execute(
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
          ),
        );
        return;
      }

      // Fallback for a missed realtime event: this fetch feeds unacknowledged
      // refunds into the shared refund stream shown by the app-level
      // observer, and drops the subscription cache when a refund exists, so
      // the access resolution below always sees the revoked state.
      await _loadRefunds(user.id);

      if (state.contours.isEmpty) {
        emit(
          state.copyWith(
            projectAccessById: const <String, ProjectAccess>{},
            showAds: false,
          ),
        );
        return;
      }

      final List<GalleryItemEntity> items = await _getGalleryItemsUseCase.execute(
        GetGalleryItemsParams(
          contours: state.contours,
          userId: user.id,
          inProgressContourIds: state.workInProgressIds.toSet(),
        ),
      );

      final SubscriptionEntity? activeSubscription = await _getActiveSubscriptionUseCase.execute(
        user.id,
      );
      final bool noAdsPurchased = await _isNoAdsPurchasedUseCase.execute(user.id);
      final bool showAds = activeSubscription?.isActiveNow() != true && !noAdsPurchased;

      emit(
        state.copyWith(
          projectAccessById: <String, ProjectAccess>{
            for (final GalleryItemEntity item in items) item.contour.id: item.access,
          },
          showAds: showAds,
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

  Future<void> _onChangeFilter(ChangeFilter event, Emitter<GalleryState> emit) async {
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

  Future<void> _onSelectCategory(SelectCategory event, Emitter<GalleryState> emit) async {
    emit(state.copyWith(selectedCategory: event.category, currentPage: 0, hasReachedMax: false));
    add(const LoadContours(reset: true));
  }

  Future<void> _onToggleFavorite(ToggleFavorite event, Emitter<GalleryState> emit) async {
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

  Future<void> _onOpenContour(OpenContour event, Emitter<GalleryState> emit) async {
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

    final bool needsRewardedAd = access == ProjectAccess.locked &&
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

  void _onAccessRequestHandled(AccessRequestHandled event, Emitter<GalleryState> emit) {
    emit(state.copyWith(clearAccessRequest: true, isLoadingAd: false));
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
