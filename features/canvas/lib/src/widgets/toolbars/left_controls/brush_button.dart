import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../../../bloc/canvas_bloc.dart';
import '../tool_selector_overlay.dart';

/// Button to select the brush tool or open the brush selection menu.
class BrushButton extends StatelessWidget {
  /// Size of the button.
  final double size;

  /// Creates a [BrushButton].
  const BrushButton({
    required this.size,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEraser = context.select(
      (CanvasBloc bloc) => bloc.state.isEraser,
    );
    final String? activeBrushId = context.select(
      (CanvasBloc bloc) => bloc.state.activeBrushId,
    );
    final List<ToolEntity> availableTools = context.select(
      (CanvasBloc bloc) => bloc.state.availableTools,
    );

    final bool isBrushActive = !isEraser;

    return AppIconButton(
      size: size,
      iconSize: 24,
      backgroundColor: Colors.transparent,
      icon: const Icon(Icons.brush),
      isActive: isBrushActive,
      onPressed: () {
        final bloc = context.read<CanvasBloc>();
        if (!isBrushActive) {
          bloc.add(const SelectTool(CanvasTool.brush));
        } else {
          _showBrushSelector(context, bloc, availableTools, activeBrushId);
        }
      },
    );
  }

  void _showBrushSelector(
    BuildContext context,
    CanvasBloc bloc,
    List<ToolEntity> brushes,
    String? activeId,
  ) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.transparent,
      pageBuilder: (dialogContext, anim1, anim2) {
        return Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.only(top: 120, left: 64),
            child: ToolSelectorOverlay(
              tools: brushes,
              activeToolId: activeId,
              onToolSelected: (id) => bloc.add(SelectBrush(id)),
            ),
          ),
        );
      },
    );
  }
}
