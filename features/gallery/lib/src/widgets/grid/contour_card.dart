import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

import 'contour_preview.dart';

/// Card widget representing a contour in the gallery grid.
class ContourCard extends StatelessWidget {
  /// Contour title.
  final String title;

  /// Contour preview URL or local file path.
  final String? previewUrl;

  /// SVG data of the contour, rendered as the preview when [previewUrl] is
  /// not a local file.
  final String? svgData;

  /// Whether the contour is marked as favorite.
  final bool isFavorite;

  /// Whether the contour has a started project.
  final bool isInProgress;

  /// Called when the card is tapped.
  final VoidCallback? onTap;

  /// Called when the favorite icon is tapped.
  final VoidCallback? onFavoriteTap;

  /// Creates a [ContourCard].
  const ContourCard({
    required this.title,
    this.previewUrl,
    this.svgData,
    this.isFavorite = false,
    this.isInProgress = false,
    this.onTap,
    this.onFavoriteTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shadowColor: colors.accentDark.withValues(alpha: 0.2),
        color: colors.secondaryBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.defaultBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ContourPreview(previewUrl: previewUrl, svgData: svgData),
            if (isInProgress)
              Positioned(
                top: 8,
                left: 8,
                child: Icon(Icons.folder, color: colors.accentDark, size: 20),
              ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: onFavoriteTap,
                child: Icon(
                  isFavorite ? Icons.star : Icons.star_border,
                  color: isFavorite ? colors.accentDark : colors.secondaryText,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
