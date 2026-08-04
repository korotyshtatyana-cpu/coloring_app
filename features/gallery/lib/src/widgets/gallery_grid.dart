import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../bloc/gallery_bloc.dart';
import 'contour_card.dart';

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
    final bool isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isPortrait ? 2 : 4,
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
        );
      },
    );
  }
}
