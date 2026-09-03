import 'package:core_ui/core_ui.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/canvas_bloc.dart';

/// Top toolbar with back, export and autosave indicator.
class TopToolbar extends StatelessWidget {
  /// Callback invoked when the export button is pressed.
  final VoidCallback onExport;

  /// Creates a [TopToolbar].
  const TopToolbar({
    required this.onExport,
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
            AppIconButton(
              size: 32,
              iconSize: 24,
              icon: const Icon(Icons.arrow_back),
              backgroundColor: Colors.transparent,
              onPressed: () {
                // Saving happens in the PopScope handler of CanvasScreen.
                context.router.maybePop();
              },
            ),
            const Spacer(),
            if (status == CanvasStatus.saving)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(Icons.sync, color: colors.green, size: 16),
              ),
            AppIconButton(
              size: 32,
              iconSize: 24,
              icon: const Icon(Icons.share),
              backgroundColor: Colors.transparent,
              onPressed: onExport,
            ),
          ],
        ),
      ),
    );
  }
}
