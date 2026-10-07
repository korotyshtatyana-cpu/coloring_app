import 'package:equatable/equatable.dart';

import 'contour_entity.dart';
import 'project_access.dart';

/// Domain entity representing a single gallery card.
///
/// Couples a contour with the access level the current user has for it, so the
/// gallery renders a fully resolved list in one pass instead of resolving
/// access per card.
class GalleryItemEntity extends Equatable {
  /// The contour shown on the card.
  final ContourEntity contour;

  /// Access level of the [contour] for the current user.
  final ProjectAccess access;

  /// Creates a [GalleryItemEntity].
  const GalleryItemEntity({required this.contour, required this.access});

  @override
  List<Object?> get props => <Object?>[contour, access];
}
