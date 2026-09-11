import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../../../bloc/canvas_bloc.dart';
import '../tool_selector_overlay.dart';

/// Button to select the eraser tool or open the eraser selection menu.
class EraserButton extends StatelessWidget {
  /// Size of the button.
  final double size;

  /// Creates an [EraserButton].
  const EraserButton({
    required this.size,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEraser = context.select(
      (CanvasBloc bloc) => bloc.state.isEraser,
    );
    final String? activeEraserId = context.select(
      (CanvasBloc bloc) => bloc.state.activeEraserId,
    );
    final List<ToolEntity> availableTools = context.select(
      (CanvasBloc bloc) => bloc.state.availableTools,
    );

    return AppIconButton(
      size: size,
      iconSize: 24,
      backgroundColor: Colors.transparent,
      icon: const Icon(Icons.auto_fix_normal),
      isActive: isEraser,
      onPressed: () {
        final bloc = context.read<CanvasBloc>();
        if (!isEraser) {
          bloc.add(const SelectTool(CanvasTool.eraser));
        } else {
          _showEraserSelector(context, bloc, availableTools, activeEraserId);
        }
      },
    );
  }

  void _showEraserSelector(
    BuildContext context,
    CanvasBloc bloc,
    List<ToolEntity> erasers,
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
            padding: const EdgeInsets.only(top: 160, left: 48),
            child: ToolSelectorOverlay(
              tools: erasers,
              activeToolId: activeId,
              onToolSelected: (id) => bloc.add(SelectEraser(id)),
            ),
          ),
        );
      },
    );
  }
}
