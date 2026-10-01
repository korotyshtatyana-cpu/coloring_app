import 'package:flutter/material.dart';

import 'contour_preview_content.dart';

/// Displays a contour preview image that smoothly cross-fades when the URL
/// changes (e.g. after a project thumbnail is re-rendered and the gallery
/// reloads).
///
/// Network images are precached before the swap so the user never sees a
/// loading placeholder mid-transition.
class ContourPreview extends StatefulWidget {
  /// The image URL (remote or local) to display.
  final String? previewUrl;

  /// URL to the SVG file.
  final String? svgUrl;

  /// Creates a [ContourPreview].
  const ContourPreview({super.key, this.previewUrl, this.svgUrl});

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
    // Always start with null (fallback SVG or placeholder) to force a
    // cross-fade to the real image once the screen is loaded.
    _displayedUrl = null;

    if (widget.previewUrl != null && widget.previewUrl!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _swapUrl(widget.previewUrl);
      });
    }
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
      duration: const Duration(milliseconds: 800),
      switchInCurve: Curves.easeInOutCubic,
      switchOutCurve: Curves.easeInOutCubic,
      child: ContourPreviewContent(
        url: _displayedUrl,
        svgUrl: widget.svgUrl,
        key: ValueKey<String?>(_displayedUrl ?? 'fallback'),
      ),
    );
  }
}
