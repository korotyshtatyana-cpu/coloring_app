import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/canvas_bloc.dart';

/// Top toolbar with back, help, export and autosave indicator.
class TopToolbar extends StatelessWidget {
  /// Callback invoked when the export button is pressed.
  final VoidCallback onExport;

  /// Callback invoked when the back button is pressed.
  final VoidCallback onBack;

  /// Callback invoked when the help/info button is pressed.
  final VoidCallback onHelp;

  /// Creates a [TopToolbar].
  const TopToolbar({
    required this.onExport,
    required this.onBack,
    required this.onHelp,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final CanvasStatus status = context.select(
      (CanvasBloc bloc) => bloc.state.status,
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: <Widget>[
            ToolbarContainer(
              isSquare: true,
              child: AppIconButton(
                size: 32,
                iconSize: 24,
                icon: const Icon(Icons.arrow_back),
                backgroundColor: Colors.transparent,
                onPressed: onBack,
              ),
            ),
            const Spacer(),
            if (status == CanvasStatus.saving)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(Icons.sync, color: colors.green, size: 16),
              ),
            ToolbarContainer(
              isSquare: true,
              backgroundColor: colors.accentDark,
              child: AppIconButton(
                size: 32,
                iconSize: 24,
                icon: Icon(Icons.share, color: colors.primaryBg),
                backgroundColor: colors.transparent,
                onPressed: onExport,
              ),
            ),
            const SizedBox(width: 8),
            ToolbarContainer(
              isSquare: true,
              child: AppIconButton(
                size: 32,
                iconSize: 24,
                icon: Icon(Icons.info_outline, color: colors.accentDark),
                backgroundColor: Colors.transparent,
                onPressed: onHelp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
