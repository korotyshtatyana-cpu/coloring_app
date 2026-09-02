import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';

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
            _ContourPreview(
              previewUrl: previewUrl,
              svgData: svgData,
            ),
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
}

class _ContourPreview extends StatelessWidget {
  final String? previewUrl;
  final String? svgData;

  const _ContourPreview({
    this.previewUrl,
    this.svgData,
  });

  @override
  Widget build(BuildContext context) {
    final String? url = previewUrl;

    // 1. Local file (thumbnail rendered on this device).
    if (url != null && url.isNotEmpty && !url.startsWith('http')) {
      if (_isSvgUrl(url)) {
        return _FadeIn(
          child: SvgPicture.file(
            File(url),
            fit: BoxFit.cover,
            placeholderBuilder: (_) => _VectorOrPlaceholder(svgData: svgData),
          ),
        );
      }
      return _FadeIn(
        child: Image.file(
          File(url),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _VectorOrPlaceholder(svgData: svgData),
        ),
      );
    }

    // 2. Remote image (project thumbnail or contour preview from Supabase).
    //    The local SVG is shown while loading and if the request fails.
    if (url != null && url.isNotEmpty) {
      if (_isSvgUrl(url)) {
        return _FadeIn(
          child: SvgPicture.network(
            url,
            fit: BoxFit.cover,
            placeholderBuilder: (_) => _VectorOrPlaceholder(svgData: svgData),
          ),
        );
      }
      return _FadeIn(
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (_, Widget child, ImageChunkEvent? loadingProgress) {
            if (loadingProgress == null) return child;
            return _VectorOrPlaceholder(svgData: svgData);
          },
          errorBuilder: (_, __, ___) => _VectorOrPlaceholder(svgData: svgData),
        ),
      );
    }

    // 3. No image at all: render the contour SVG locally.
    if (svgData != null && svgData!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: _FadeIn(
          child: SvgPicture.string(
            svgData!,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    return const _ContourPlaceholder();
  }

  bool _isSvgUrl(String url) {
    final String lower = url.toLowerCase();
    if (lower.endsWith('.svg')) return true;
    final String? path = Uri.tryParse(url)?.path.toLowerCase();
    return path != null && path.endsWith('.svg');
  }
}

class _VectorOrPlaceholder extends StatelessWidget {
  final String? svgData;

  const _VectorOrPlaceholder({this.svgData});

  @override
  Widget build(BuildContext context) {
    if (svgData != null && svgData!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: SvgPicture.string(
          svgData!,
          fit: BoxFit.contain,
        ),
      );
    }
    return const _ContourPlaceholder();
  }
}

class _ContourPlaceholder extends StatelessWidget {
  const _ContourPlaceholder();

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return Container(
      color: colors.secondaryBg,
      padding: const EdgeInsets.all(12),
      child: Icon(
        Icons.image,
        color: colors.primaryBg,
        size: 48,
      ),
    );
  }
}

class _FadeIn extends StatefulWidget {
  final Widget child;

  const _FadeIn({required this.child});

  @override
  State<_FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<_FadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: widget.child,
    );
  }
}
