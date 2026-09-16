import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

/// Builder for the slider interaction overlay.
typedef SliderOverlayBuilder = Widget Function(
  BuildContext context,
  double value,
);

/// A vertical slider wrapper for toolbar controls.
/// Supports responsive overlays.
class VerticalControlSlider extends StatefulWidget {
  /// Current slider value.
  final double value;

  /// Minimum value.
  final double min;

  /// Maximum value.
  final double max;

  /// Height of the slider.
  final double height;

  /// Callback for value changes.
  final ValueChanged<double> onChanged;

  /// Optional builder for the interaction overlay.
  final SliderOverlayBuilder? overlayBuilder;

  /// Creates a [VerticalControlSlider].
  const VerticalControlSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.height,
    required this.onChanged,
    this.overlayBuilder,
    super.key,
  });

  @override
  State<VerticalControlSlider> createState() => _VerticalControlSliderState();
}

class _VerticalControlSliderState extends State<VerticalControlSlider> {
  OverlayEntry? _overlayEntry;
  bool _isOverlayInserted = false;

  void _showOverlay() {
    if (widget.overlayBuilder == null || !mounted) return;

    _hideOverlay();

    final OverlayEntry localEntry = OverlayEntry(
      builder: (BuildContext dialogContext) {
        return OrientationBuilder(
          builder: (context, orientation) {
            final MediaQueryData mq = MediaQuery.of(context);
            final bool isPhone = mq.size.shortestSide < 600;
            final bool isLandscape = orientation == Orientation.landscape;

            final RenderBox? renderBox = this.context.findRenderObject() as RenderBox?;
            double top = 160;
            if (renderBox != null) {
              final Offset offset = renderBox.localToGlobal(Offset.zero);
              // Center the overlay relative to the slider height
              // (approx 130px is the height of SliderOverlay content)
              top = offset.dy + (renderBox.size.height - 130) / 2;
            }

            final double left = isPhone && isLandscape ? 120 : 64;

            return Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: EdgeInsets.only(left: left, top: top),
                child: widget.overlayBuilder!(context, widget.value),
              ),
            );
          },
        );
      },
    );

    _overlayEntry = localEntry;

    final overlay = Overlay.of(context, debugRequiredFor: widget);
    // Use standard microtask or postframe callback to prevent synchronous insert issues,
    // but check our tracking flag first to prevent concurrent duplicate additions.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _overlayEntry == localEntry && !_isOverlayInserted) {
        overlay.insert(localEntry);
        _isOverlayInserted = true;
      }
    });
  }

  void _updateOverlay() {
    if (_overlayEntry != null && _isOverlayInserted) {
      // Defer markNeedsBuild to the next frame to avoid "rebuild during build" error
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_overlayEntry != null && _isOverlayInserted) {
          _overlayEntry?.markNeedsBuild();
        }
      });
    }
  }

  void _hideOverlay() {
    if (_overlayEntry != null) {
      if (_isOverlayInserted) {
        _overlayEntry?.remove();
        _isOverlayInserted = false;
      }
      _overlayEntry = null;
    }
  }

  @override
  void didUpdateWidget(VerticalControlSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_overlayEntry != null && oldWidget.value != widget.value) {
      _updateOverlay();
    }
  }

  @override
  void dispose() {
    _hideOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return SizedBox(
      height: widget.height,
      width: 32,
      child: GradientSlider(
        value: (widget.value - widget.min) / (widget.max - widget.min),
        onChanged: (double normalizedValue) {
          widget.onChanged(
            widget.min + normalizedValue * (widget.max - widget.min),
          );
        },
        activeColor: colors.accentDark,
        inactiveColor: colors.secondaryText.withValues(alpha: 0.2),
        trackHeight: 8,
        thumbRadius: 10,
        isVertical: true,
        onStarted: _showOverlay,
        onStopped: _hideOverlay,
      ),
    );
  }
}
