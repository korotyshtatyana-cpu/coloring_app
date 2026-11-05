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

/// One-shot request produced after the user tries to open a contour.
///
/// The UI reacts to a new [id] by navigating to the canvas when [granted] is
/// `true`, or by showing an error when a rewarded ad was not completed.
class AccessRequest extends Equatable {
  /// Monotonic identifier so repeated outcomes still reach the listener.
  final int id;

  /// Contour the user tried to open.
  final String contourId;

  /// Whether access was granted and the canvas should open.
  final bool granted;

  /// How the rewarded ad ended, or `null` when no ad was required.
  final RewardedAdOutcome? outcome;

  /// Whether this project can only be viewed, not edited.
  final bool viewOnly;

  /// Creates an [AccessRequest].
  const AccessRequest({
    required this.id,
    required this.contourId,
    required this.granted,
    this.outcome,
    this.viewOnly = false,
  });

  @override
  List<Object?> get props => <Object?>[id, contourId, granted, outcome, viewOnly];
}

/// State of the gallery feature.
class GalleryState extends Equatable {
  /// Current loading status.
  final GalleryStatus status;

  /// Loaded contours.
  final List<ContourEntity> contours;

  /// Categories that have at least one contour.
  final List<ContourCategory> availableCategories;

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

  /// Access level of each loaded contour, keyed by contour id.
  ///
  /// Stays empty until the monetization status resolves, so the cards render
  /// without access icons while the request is in flight.
  final Map<String, ProjectAccess> projectAccessById;

  /// Whether the gallery should display the bottom banner ad.
  ///
  /// `false` while the monetization status is unknown and for users with an
  /// active subscription or a lifetime No Ads purchase.
  final bool showAds;

  /// Pending one-shot access request, if any.
  final AccessRequest? accessRequest;

  /// Whether a rewarded ad is currently loading.
  final bool isLoadingAd;

  /// Creates a [GalleryState].
  const GalleryState({
    this.status = GalleryStatus.initial,
    this.contours = const <ContourEntity>[],
    this.availableCategories = const <ContourCategory>[],
    this.error,
    this.activeFilter = FilterType.all,
    this.selectedCategory = ContourCategory.all,
    this.currentPage = 0,
    this.hasReachedMax = false,
    this.favoriteIds = const <String>[],
    this.workInProgressIds = const <String>[],
    this.workInProgressThumbnails = const <String, String?>{},
    this.projectAccessById = const <String, ProjectAccess>{},
    this.showAds = false,
    this.accessRequest,
    this.isLoadingAd = false,
  });

  @override
  List<Object?> get props => <Object?>[
    status,
    contours,
    availableCategories,
    error,
    activeFilter,
    selectedCategory,
    currentPage,
    hasReachedMax,
    favoriteIds,
    workInProgressIds,
    workInProgressThumbnails,
    projectAccessById,
    showAds,
    accessRequest,
    isLoadingAd,
  ];

  /// Creates a copy with optional new values.
  /// Pass [selectedCategory] explicitly to change it; omitting keeps the current value.
  GalleryState copyWith({
    GalleryStatus? status,
    List<ContourEntity>? contours,
    List<ContourCategory>? availableCategories,
    String? error,
    FilterType? activeFilter,
    ContourCategory? selectedCategory,
    int? currentPage,
    bool? hasReachedMax,
    List<String>? favoriteIds,
    List<String>? workInProgressIds,
    Map<String, String?>? workInProgressThumbnails,
    Map<String, ProjectAccess>? projectAccessById,
    bool? showAds,
    AccessRequest? accessRequest,
    bool clearAccessRequest = false,
    bool? isLoadingAd,
  }) {
    return GalleryState(
      status: status ?? this.status,
      contours: contours ?? this.contours,
      availableCategories: availableCategories ?? this.availableCategories,
      error: error ?? this.error,
      activeFilter: activeFilter ?? this.activeFilter,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      currentPage: currentPage ?? this.currentPage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      favoriteIds: favoriteIds ?? this.favoriteIds,
      workInProgressIds: workInProgressIds ?? this.workInProgressIds,
      workInProgressThumbnails: workInProgressThumbnails ?? this.workInProgressThumbnails,
      projectAccessById: projectAccessById ?? this.projectAccessById,
      showAds: showAds ?? this.showAds,
      accessRequest: clearAccessRequest ? null : (accessRequest ?? this.accessRequest),
      isLoadingAd: isLoadingAd ?? this.isLoadingAd,
    );
  }
}
