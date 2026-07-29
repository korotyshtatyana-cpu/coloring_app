import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

/// Eyedropper overlay showing a magnified area around the picked position.
class EyedropperOverlay extends StatelessWidget {
  /// Current pointer position.
  final Offset position;

  /// Size of the loupe.
  final double size;

  /// Creates an [EyedropperOverlay].
  const EyedropperOverlay({
    required this.position,
    this.size = 80,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return Positioned(
      left: position.dx - size / 2,
      top: position.dy - size,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: colors.secondaryBg, width: 2),
          color: colors.primaryBg,
        ),
        child: Center(
          child: Container(
            width: 2,
            height: 2,
            color: colors.secondaryBg,
          ),
        ),
      ),
    );
  }
}
