import 'dart:async';

import 'package:core/core.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';

part 'gallery_event.dart';
part 'gallery_state.dart';

/// BLoC responsible for loading and filtering gallery contours.
class GalleryBloc extends Bloc<GalleryEvent, GalleryState> {
  final GetContoursUseCase _getContoursUseCase;
  final GetContoursByIdsUseCase _getContoursByIdsUseCase;
  final ToggleFavoriteUseCase _toggleFavoriteUseCase;
  final GetFavoriteIdsUseCase _getFavoriteIdsUseCase;
  final GetWorkInProgressUseCase _getWorkInProgressUseCase;

  /// Creates a [GalleryBloc] with the required use cases.
  GalleryBloc({
    required this._getContoursUseCase,
    required this._getContoursByIdsUseCase,
    required this._toggleFavoriteUseCase,
    required this._getFavoriteIdsUseCase,
    required this._getWorkInProgressUseCase,
  })  : super(const GalleryState()) {
    on<LoadContours>(
      _onLoadContours,
      transformer: droppable(),
    );
    on<ChangeFilter>(_onChangeFilter);
    on<SelectCategory>(_onSelectCategory);
    on<ToggleFavorite>(_onToggleFavorite);
  }

  Future<void> _onLoadContours(
    LoadContours event,
    Emitter<GalleryState> emit,
  ) async {
    try {
      emit(state.copyWith(
        status: GalleryStatus.loading,
        error: null,
      ));

      // Fetch favorites and WIP IDs only on reset (first load or filter change)
      List<String> favoriteIds = state.favoriteIds;
      List<String> workInProgressIds = state.workInProgressIds;

      if (event.reset) {
        favoriteIds = await _getFavoriteIdsUseCase.execute();
        workInProgressIds = await _getWorkInProgressUseCase.execute();
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
        contours = event.reset
            ? pageContours
            : <ContourEntity>[...state.contours, ...pageContours];
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

      emit(state.copyWith(
        status: GalleryStatus.success,
        contours: contours,
        currentPage: currentPage,
        hasReachedMax: hasReachedMax,
        error: null,
        favoriteIds: favoriteIds,
        workInProgressIds: workInProgressIds,
      ));
    } catch (e, stackTrace) {
      ErrorHandler.report(e, stackTrace);
      emit(state.copyWith(
        status: GalleryStatus.failure,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onChangeFilter(
    ChangeFilter event,
    Emitter<GalleryState> emit,
  ) async {
    emit(state.copyWith(
      activeFilter: event.filter,
      selectedCategory: ContourCategory.all,
      currentPage: 0,
      hasReachedMax: false,
    ));
    add(const LoadContours(reset: true));
  }

  Future<void> _onSelectCategory(
    SelectCategory event,
    Emitter<GalleryState> emit,
  ) async {
    emit(state.copyWith(
      selectedCategory: event.category,
      currentPage: 0,
      hasReachedMax: false,
    ));
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
}
