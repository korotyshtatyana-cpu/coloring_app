import 'package:flutter/widgets.dart';

/// Wraps the color picker in a scrollable area with a scrollbar that is only
/// shown when the content does not fit in the available height.
class PickerScrollView extends StatefulWidget {
  final Widget child;

  const PickerScrollView({super.key, required this.child});

  @override
  State<PickerScrollView> createState() => _PickerScrollViewState();
}

class _PickerScrollViewState extends State<PickerScrollView> {
  final ScrollController _controller = ScrollController();
  bool _needsScrollbar = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateScrollbar);
    // Determine whether the content overflows on the first frame so the
    // scrollbar is visible immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollbar());
  }

  @override
  void didUpdateWidget(covariant PickerScrollView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-evaluate after the first frame so the scroll extent is known.
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollbar());
  }

  @override
  void dispose() {
    _controller.removeListener(_updateScrollbar);
    _controller.dispose();
    super.dispose();
  }

  void _updateScrollbar() {
    final bool scrollable =
        _controller.hasClients && _controller.position.maxScrollExtent > 0;
    if (scrollable != _needsScrollbar) {
      setState(() => _needsScrollbar = scrollable);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double maxHeight = MediaQuery.sizeOf(context).height - 96 - 16 - 32;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: RawScrollbar(
        controller: _controller,
        thumbVisibility: _needsScrollbar,
        mainAxisMargin: 16,
        thickness: 6,
        radius: const Radius.circular(6),
        child: SingleChildScrollView(
          controller: _controller,
          padding: const EdgeInsets.only(right: 4),
          child: widget.child,
        ),
      ),
    );
  }
}
