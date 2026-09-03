import 'package:flutter/widgets.dart';
import 'dart:io';
import 'package:flutter_svg/flutter_svg.dart';

import 'contour_placeholder.dart';
import 'fade_in.dart';
import 'vector_or_placeholder.dart';

class ContourPreview extends StatelessWidget {
  final String? previewUrl;
  final String? svgData;

  const ContourPreview({super.key, this.previewUrl, this.svgData});

  @override
  Widget build(BuildContext context) {
    final String? url = previewUrl;

    // 1. Local file (thumbnail rendered on this device).
    if (url != null && url.isNotEmpty && !url.startsWith('http')) {
      if (_isSvgUrl(url)) {
        return FadeIn(
          child: SvgPicture.file(
            File(url),
            fit: BoxFit.cover,
            placeholderBuilder: (_) => VectorOrPlaceholder(svgData: svgData),
          ),
        );
      }
      return FadeIn(
        child: Image.file(
          File(url),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => VectorOrPlaceholder(svgData: svgData),
        ),
      );
    }

    // 2. Remote image (project thumbnail or contour preview from Supabase).
    //    The local SVG is shown while loading and if the request fails.
    if (url != null && url.isNotEmpty) {
      if (_isSvgUrl(url)) {
        return FadeIn(
          child: SvgPicture.network(
            url,
            fit: BoxFit.cover,
            placeholderBuilder: (_) => VectorOrPlaceholder(svgData: svgData),
          ),
        );
      }
      return FadeIn(
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (_, Widget child, ImageChunkEvent? loadingProgress) {
            if (loadingProgress == null) return child;
            return VectorOrPlaceholder(svgData: svgData);
          },
          errorBuilder: (_, __, ___) => VectorOrPlaceholder(svgData: svgData),
        ),
      );
    }

    // 3. No image at all: render the contour SVG locally.
    if (svgData != null && svgData!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: FadeIn(child: SvgPicture.string(svgData!, fit: BoxFit.contain)),
      );
    }

    return const ContourPlaceholder();
  }

  bool _isSvgUrl(String url) {
    final String lower = url.toLowerCase();
    if (lower.endsWith('.svg')) return true;
    final String? path = Uri.tryParse(url)?.path.toLowerCase();
    return path != null && path.endsWith('.svg');
  }
}
