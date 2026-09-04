import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'contour_placeholder.dart';
import 'vector_or_placeholder.dart';

/// Displays a contour preview image that smoothly cross-fades when the URL
/// changes (e.g. after a project thumbnail is re-rendered and the gallery
/// reloads).
///
/// Network images are precached before the swap so the user never sees a
/// loading placeholder mid-transition.
class ContourPreview extends StatefulWidget {
  final String? previewUrl;
  final String? svgData;

  const ContourPreview({super.key, this.previewUrl, this.svgData});

  @override
  State<ContourPreview> createState() => _ContourPreviewState();
}

class _ContourPreviewState extends State<ContourPreview> {
  /// The URL currently being rendered (lags behind [widget.previewUrl]
  /// while a new network image is being precached).
  String? _displayedUrl;

  @override
  void initState() {
    super.initState();
    _displayedUrl = widget.previewUrl;
  }

  @override
  void didUpdateWidget(ContourPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.previewUrl == widget.previewUrl) return;
    _swapUrl(widget.previewUrl);
  }

  void _swapUrl(String? newUrl) {
    if (newUrl == null || newUrl.isEmpty) {
      setState(() => _displayedUrl = newUrl);
      return;
    }

    // Local files are instant — no need to precache.
    if (!newUrl.startsWith('http')) {
      setState(() => _displayedUrl = newUrl);
      return;
    }

    // Network image: precache first, then swap so AnimatedSwitcher can
    // cross-fade from the fully-loaded old image to the fully-loaded new one.
    precacheImage(
      NetworkImage(newUrl),
      context,
      onError: (_, __) {
        // On error, still swap so the user doesn't see a stale image forever.
        if (mounted) setState(() => _displayedUrl = newUrl);
      },
    ).then((_) {
      if (mounted && _displayedUrl != newUrl) {
        setState(() => _displayedUrl = newUrl);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.easeOut,
      child: _buildPreview(_displayedUrl),
    );
  }

  Widget _buildPreview(String? url) {
    // 1. Local file (thumbnail rendered on this device).
    if (url != null && url.isNotEmpty && !url.startsWith('http')) {
      if (_isSvgUrl(url)) {
        return SvgPicture.file(
          File(url),
          key: ValueKey<String>(url),
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          placeholderBuilder: (_) =>
              VectorOrPlaceholder(svgData: widget.svgData),
        );
      }
      return Image.file(
        File(url),
        key: ValueKey<String>(url),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            VectorOrPlaceholder(svgData: widget.svgData),
      );
    }

    // 2. Remote image (project thumbnail or contour preview from Supabase).
    //    Because we precache before swapping the URL, the image is already
    //    decoded by the time AnimatedSwitcher starts the cross-fade.
    if (url != null && url.isNotEmpty) {
      if (_isSvgUrl(url)) {
        return SvgPicture.network(
          url,
          key: ValueKey<String>(url),
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          placeholderBuilder: (_) =>
              VectorOrPlaceholder(svgData: widget.svgData),
        );
      }
      return Image.network(
        url,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        key: ValueKey<String>(url),
        frameBuilder:
            (_, Widget child, int? frame, bool wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded || frame != null) return child;
              return VectorOrPlaceholder(svgData: widget.svgData);
            },
        errorBuilder: (_, __, ___) =>
            VectorOrPlaceholder(svgData: widget.svgData),
      );
    }

    // 3. No image at all: render the contour SVG locally.
    if (widget.svgData != null && widget.svgData!.isNotEmpty) {
      return SvgPicture.string(
        widget.svgData!,
        key: const ValueKey<String>('svg-fallback'),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
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
