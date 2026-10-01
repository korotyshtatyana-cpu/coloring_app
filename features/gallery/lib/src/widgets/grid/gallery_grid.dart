import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../../bloc/gallery_bloc.dart';
import 'gallery_contour_card.dart';

/// Grid displaying gallery contours.
class GalleryGrid extends StatelessWidget {
  /// State of the gallery.
  final GalleryState state;

  /// Creates [GalleryGrid].
  const GalleryGrid({
    required this.state,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final bool isPortrait = size.height > size.width;
    final bool isTablet = ResponsiveHelper.isTablet(context);

    int crossAxisCount;
    if (isPortrait) {
      crossAxisCount = isTablet ? 3 : 2;
    } else {
      crossAxisCount = 4;
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: state.contours.length,
      itemBuilder: (BuildContext context, int index) {
        final ContourEntity contour = state.contours[index];
        final bool isFavorite = state.favoriteIds.contains(contour.id);
        final bool isInProgress = state.workInProgressIds.contains(contour.id);

        return GalleryContourCard(
          contour: contour,
          isFavorite: isFavorite,
          isInProgress: isInProgress,
          thumbnailPath: state.workInProgressThumbnails[contour.id],
        );
      },
    );
  }
}
