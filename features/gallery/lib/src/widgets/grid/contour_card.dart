import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

import 'contour_preview.dart';

/// Card widget representing a contour in the gallery grid.
class ContourCard extends StatelessWidget {
  /// Contour title.
  final String title;

  /// Contour preview URL or local file path.
  final String? previewUrl;

  /// URL to the SVG file.
  final String? svgUrl;

  /// Whether the contour is marked as favorite.
  final bool isFavorite;

  /// Whether the contour has a started project.
  final bool isInProgress;

  /// Called when the card is tapped.
  final VoidCallback? onTap;

  /// Called when the favorite icon is tapped.
  final VoidCallback? onFavoriteTap;

  /// Badge rendered in the top-right corner, typically the access-type icon.
  final Widget? accessBadge;

  /// Creates a [ContourCard].
  const ContourCard({
    required this.title,
    this.previewUrl,
    this.svgUrl,
    this.isFavorite = false,
    this.isInProgress = false,
    this.onTap,
    this.onFavoriteTap,
    this.accessBadge,
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
            ContourPreview(previewUrl: previewUrl, svgUrl: svgUrl),
            // if (isInProgress)
            //   Positioned(
            //     top: 8,
            //     left: 8,
            //     child: Icon(Icons.folder, color: colors.accentDark, size: 20),
            //   ),
            if (accessBadge != null)
              Positioned(top: 0, right: 0, child: accessBadge!),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: onFavoriteTap,
                child: Container(
                  key: const ValueKey<String>('access-badge'),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: colors.accentDark.withValues(alpha: 0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    isFavorite ? Icons.star : Icons.star_border,
                    color: isFavorite
                        ? colors.accentDark
                        : colors.secondaryText,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
