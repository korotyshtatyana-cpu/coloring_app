part of 'gallery_bloc.dart';

/// Base class for gallery events.
abstract class GalleryEvent extends Equatable {
  /// Creates a [GalleryEvent].
  const GalleryEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Loads contours with optional reset.
class LoadContours extends GalleryEvent {
  /// Whether to replace the current list.
  final bool reset;

  /// Creates a [LoadContours] event.
  const LoadContours({this.reset = false});

  @override
  List<Object?> get props => <Object?>[reset];
}

/// Changes the active filter.
class ChangeFilter extends GalleryEvent {
  /// New filter type.
  final FilterType filter;

  /// Creates a [ChangeFilter] event.
  const ChangeFilter(this.filter);

  @override
  List<Object?> get props => <Object?>[filter];
}

/// Selects a category.
class SelectCategory extends GalleryEvent {
  /// Selected category.
  final String category;

  /// Creates a [SelectCategory] event.
  const SelectCategory(this.category);

  @override
  List<Object?> get props => <Object?>[category];
}

/// Toggles favorite status of a contour.
class ToggleFavorite extends GalleryEvent {
  /// Contour identifier.
  final String contourId;

  /// Creates a [ToggleFavorite] event.
  const ToggleFavorite(this.contourId);

  @override
  List<Object?> get props => <Object?>[contourId];
}

/// Filter types for the gallery.
enum FilterType {
  /// All available contours.
  all,

  /// Favorited contours.
  favorites,

  /// Contours with started projects.
  inProgress,
}
