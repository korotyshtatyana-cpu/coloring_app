import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_fonts.dart';

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
        color: colors.secondaryBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.defaultBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            _buildPreview(colors),
            if (isInProgress)
              Positioned(
                top: 8,
                left: 8,
                child: Icon(
                  Icons.folder,
                  color: colors.yellow,
                  size: 20,
                ),
              ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: onFavoriteTap,
                child: Icon(
                  isFavorite ? Icons.star : Icons.star_border,
                  color: isFavorite ? colors.yellow : colors.primaryText,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(AppColors colors) {
    final String? url = previewUrl;

    // Local file previews (e.g. rendered project thumbnails) take priority.
    if (url != null && url.isNotEmpty && !url.startsWith('http')) {
      if (_isSvgUrl(url)) {
        return SvgPicture.file(
          File(url),
          fit: BoxFit.cover,
          placeholderBuilder: (_) => _buildVectorOrPlaceholder(colors),
        );
      }
      return Image.file(
        File(url),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildVectorOrPlaceholder(colors),
      );
    }

    // The contour SVG is always available locally: render it instead of
    // relying on a remote preview.
    final String? svg = svgData;
    if (svg != null && svg.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: SvgPicture.string(
          svg,
          fit: BoxFit.contain,
        ),
      );
    }

    if (url != null && url.isNotEmpty) {
      final bool isSvg = _isSvgUrl(url);
      if (isSvg) {
        return SvgPicture.network(
          url,
          fit: BoxFit.cover,
          placeholderBuilder: (_) => _buildPlaceholder(colors, url: url),
        );
      }
      return Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (_, Widget child, ImageChunkEvent? loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildPlaceholder(colors, url: url);
        },
        errorBuilder: (_, __, ___) => _buildPlaceholder(colors, url: url),
      );
    }

    return _buildPlaceholder(colors);
  }

  Widget _buildVectorOrPlaceholder(AppColors colors) {
    final String? svg = svgData;
    if (svg != null && svg.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: SvgPicture.string(
          svg,
          fit: BoxFit.contain,
        ),
      );
    }
    return _buildPlaceholder(colors);
  }

  bool _isSvgUrl(String url) {
    final String lower = url.toLowerCase();
    if (lower.endsWith('.svg')) return true;

    final String? path = Uri.tryParse(url)?.path.toLowerCase();
    if (path != null && path.endsWith('.svg')) return true;

    // If the URL has no obvious raster extension, treat it as SVG
    // (e.g. https://placehold.co/... returns SVG by default).
    const List<String> rasterExtensions = <String>[
      '.png',
      '.jpg',
      '.jpeg',
      '.gif',
      '.webp',
      '.bmp',
    ];
    final bool hasRasterExtension = rasterExtensions.any(lower.endsWith);
    return !hasRasterExtension;
  }

  Widget _buildPlaceholder(AppColors colors, {String? url}) {
    return Container(
      color: colors.secondaryBg,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.image,
            color: colors.primaryBg,
            size: 48,
          ),
          if (url != null && url.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              url,
              style: AppFonts.normal12.copyWith(color: colors.primaryBg),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
