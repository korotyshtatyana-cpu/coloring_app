import 'package:flutter/material.dart';

import 'contour_preview_content.dart';

/// Displays a contour preview image that smoothly cross-fades when the URL
/// changes.
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
  String? _displayedUrl;

  @override
  void initState() {
    super.initState();
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

    if (!newUrl.startsWith('http')) {
      setState(() => _displayedUrl = newUrl);
      return;
    }

    precacheImage(
      NetworkImage(newUrl),
      context,
      onError: (_, __) {
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
