import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

/// Visual sample of a brush inside the tool picker.
///
/// Uses the configured image when the backend provides one. Until design
/// assets exist, soft brushes get a blurred bar so they are distinguishable
/// from the standard hard-edged brushes.
class ToolPreview extends StatelessWidget {
  /// Tool whose sample stroke is shown.
  final ToolEntity tool;

  /// Creates a [ToolPreview].
  const ToolPreview({required this.tool, super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    final Widget placeholder = Icon(Icons.gesture, size: 16, color: colors.secondaryText);

    if (tool.previewPath.isEmpty) {
      return placeholder;
    }

    return Opacity(
      opacity: 0.8,
      child: Image.network(
        tool.previewPath,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => placeholder,
        frameBuilder: (_, Widget? child, ___, ____) => Padding(
          padding: const EdgeInsets.all(4),
          child: child,
        ),
      ),
    );
  }
}
