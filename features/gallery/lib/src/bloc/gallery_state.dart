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

  /// Selected category. `ContourCategory.all` means no category filter.
  final ContourCategory selectedCategory;

  /// Current pagination page.
  final int currentPage;

  /// Whether all pages have been loaded.
  final bool hasReachedMax;

  /// Favorite contour identifiers.
  final List<String> favoriteIds;

  /// Contour identifiers with started projects.
  final List<String> workInProgressIds;

  /// Started projects mapped to their thumbnail file paths, if any.
  final Map<String, String?> workInProgressThumbnails;

  /// Creates a [GalleryState].
  const GalleryState({
    this.status = GalleryStatus.initial,
    this.contours = const <ContourEntity>[],
    this.error,
    this.activeFilter = FilterType.all,
    this.selectedCategory = ContourCategory.all,
    this.currentPage = 0,
    this.hasReachedMax = false,
    this.favoriteIds = const <String>[],
    this.workInProgressIds = const <String>[],
    this.workInProgressThumbnails = const <String, String?>{},
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
    workInProgressThumbnails,
  ];

  /// Creates a copy with optional new values.
  /// Pass [selectedCategory] explicitly to change it; omitting keeps the current value.
  GalleryState copyWith({
    GalleryStatus? status,
    List<ContourEntity>? contours,
    String? error,
    FilterType? activeFilter,
    ContourCategory? selectedCategory,
    int? currentPage,
    bool? hasReachedMax,
    List<String>? favoriteIds,
    List<String>? workInProgressIds,
    Map<String, String?>? workInProgressThumbnails,
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
      workInProgressThumbnails:
          workInProgressThumbnails ?? this.workInProgressThumbnails,
    );
  }
}
