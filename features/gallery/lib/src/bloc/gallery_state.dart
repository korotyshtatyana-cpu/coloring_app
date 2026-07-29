part of 'gallery_bloc.dart';

/// Gallery loading status.
enum GalleryStatus {
  /// Initial state.
  initial,

  /// Loading contours.
  loading,

  /// Contours loaded successfully.
  success,

  /// Failed to load contours.
  failure,
}

/// State of the gallery feature.
class GalleryState extends Equatable {
  /// Current loading status.
  final GalleryStatus status;

  /// Loaded contours.
  final List<ContourEntity> contours;

  /// Error message, if any.
  final String? error;

  /// Active filter.
  final FilterType activeFilter;

  /// Selected category.
  final String? selectedCategory;

  /// Current pagination page.
  final int currentPage;

  /// Whether all pages have been loaded.
  final bool hasReachedMax;

  /// Favorite contour identifiers.
  final List<String> favoriteIds;

  /// Contour identifiers with started projects.
  final List<String> workInProgressIds;

  /// Creates a [GalleryState].
  const GalleryState({
    this.status = GalleryStatus.initial,
    this.contours = const <ContourEntity>[],
    this.error,
    this.activeFilter = FilterType.all,
    this.selectedCategory,
    this.currentPage = 0,
    this.hasReachedMax = false,
    this.favoriteIds = const <String>[],
    this.workInProgressIds = const <String>[],
  });

  @override
  List<Object?> get props => <Object?>[
        status,
        contours,
        error,
        activeFilter,
        selectedCategory,
        currentPage,
        hasReachedMax,
        favoriteIds,
        workInProgressIds,
      ];

  /// Creates a copy with optional new values.
  GalleryState copyWith({
    GalleryStatus? status,
    List<ContourEntity>? contours,
    String? error,
    FilterType? activeFilter,
    String? selectedCategory,
    int? currentPage,
    bool? hasReachedMax,
    List<String>? favoriteIds,
    List<String>? workInProgressIds,
  }) {
    return GalleryState(
      status: status ?? this.status,
      contours: contours ?? this.contours,
      error: error ?? this.error,
      activeFilter: activeFilter ?? this.activeFilter,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      currentPage: currentPage ?? this.currentPage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      favoriteIds: favoriteIds ?? this.favoriteIds,
      workInProgressIds: workInProgressIds ?? this.workInProgressIds,
    );
  }
}
