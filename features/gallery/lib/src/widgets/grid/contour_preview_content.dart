import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'contour_placeholder.dart';
import 'vector_or_placeholder.dart';

/// Renders the actual image or SVG content for [ContourPreview].
class ContourPreviewContent extends StatelessWidget {
  /// The image URL or local file path to display.
  final String? url;

  /// URL to the SVG file.
  final String? svgUrl;

  /// Creates a [ContourPreviewContent].
  const ContourPreviewContent({
    required this.url,
    required this.svgUrl,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Local file (thumbnail rendered on this device).
    if (url != null && url!.isNotEmpty && !url!.startsWith('http')) {
      if (_isSvgUrl(url!)) {
        return SvgPicture.file(
          File(url!),
          key: ValueKey<String>(url!),
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          placeholderBuilder: (_) => VectorOrPlaceholder(svgUrl: svgUrl),
        );
      }
      return Image.file(
        File(url!),
        key: ValueKey<String>(url!),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => VectorOrPlaceholder(svgUrl: svgUrl),
      );
    }

    // 2. Remote image (project thumbnail or contour preview from Supabase).
    if (url != null && url!.isNotEmpty) {
      if (_isSvgUrl(url!)) {
        return SvgPicture.network(
          url!,
          key: ValueKey<String>(url!),
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          placeholderBuilder: (_) => VectorOrPlaceholder(svgUrl: svgUrl),
        );
      }
      return Image.network(
        url!,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        key: ValueKey<String>(url!),
        frameBuilder: (_, Widget child, int? frame, bool wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) return child;
          return VectorOrPlaceholder(svgUrl: svgUrl);
        },
        errorBuilder: (_, __, ___) => VectorOrPlaceholder(svgUrl: svgUrl),
      );
    }

    // 3. No image at all: render the contour SVG from its own URL.
    if (svgUrl != null && svgUrl!.isNotEmpty) {
      return SvgPicture.network(
        svgUrl!,
        key: ValueKey<String>(svgUrl!),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        placeholderBuilder: (_) => const ContourPlaceholder(),
      );
    }

    return const ContourPlaceholder(key: ValueKey<String>('placeholder'));
  }

  bool _isSvgUrl(String url) {
    final String lower = url.toLowerCase();
    if (lower.endsWith('.svg')) return true;
    final String? path = Uri.tryParse(url)?.path.toLowerCase();
    return path != null && path.endsWith('.svg');
  }
}
