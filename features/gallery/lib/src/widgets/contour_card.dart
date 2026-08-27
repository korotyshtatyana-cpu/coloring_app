import 'package:auto_route/auto_route.dart';
import 'package:canvas/canvas.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/gallery_bloc.dart';

/// Gallery-specific card displaying a contour preview and actions.
class GalleryContourCard extends StatelessWidget {
  /// Contour entity to display.
  final ContourEntity contour;

  /// Whether the contour is favorited.
  final bool isFavorite;

  /// Whether the contour has a started project.
  final bool isInProgress;

  /// Creates a [GalleryContourCard].
  const GalleryContourCard({
    required this.contour,
    required this.isFavorite,
    required this.isInProgress,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ContourCard(
      title: contour.title,
      previewUrl: contour.previewUrl,
      isFavorite: isFavorite,
      isInProgress: isInProgress,
      onTap: () => _onTap(context),
      onFavoriteTap: () => _onFavoriteTap(context),
    );
  }

  void _onTap(BuildContext context) {
    context.router.push(CanvasRoute(contourId: contour.id)).then((_) {
      // Refresh so the work-in-progress mark appears for the contour that
      // was just edited.
      if (context.mounted) {
        context.read<GalleryBloc>().add(const LoadContours(reset: true));
      }
    });
  }

  void _onFavoriteTap(BuildContext context) {
    context.read<GalleryBloc>().add(ToggleFavorite(contour.id));
  }
}
