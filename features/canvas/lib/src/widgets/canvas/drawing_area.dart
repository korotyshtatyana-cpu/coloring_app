import 'package:flutter/material.dart';
import 'canvas_stack.dart';

/// Drawing area with interactive viewer and pointer listener.
class DrawingArea extends StatelessWidget {
  /// Key for capturing the drawing for the eyedropper.
  final GlobalKey repaintKey;

  /// Controller for zoom and pan.
  final TransformationController transformationController;

  /// Pointer events.
  final PointerDownEventListener onPointerDown;
  final PointerMoveEventListener onPointerMove;
  final PointerUpEventListener onPointerUp;
  final PointerCancelEventListener onPointerCancel;

  /// Creates a [DrawingArea].
  const DrawingArea({
    required this.repaintKey,
    required this.transformationController,
    required this.onPointerDown,
    required this.onPointerMove,
    required this.onPointerUp,
    required this.onPointerCancel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: RepaintBoundary(
            key: repaintKey,
            child: InteractiveViewer(
              transformationController: transformationController,
              boundaryMargin: const EdgeInsets.all(64.0),
              minScale: 0.5,
              maxScale: 5.0,
              panEnabled: false,
              scaleEnabled: false,
              child: const CanvasStack(),
            ),
          ),
        ),
        Positioned.fill(
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: onPointerDown,
            onPointerMove: onPointerMove,
            onPointerUp: onPointerUp,
            onPointerCancel: onPointerCancel,
            child: Container(color: Colors.transparent),
          ),
        ),
      ],
    );
  }
}
