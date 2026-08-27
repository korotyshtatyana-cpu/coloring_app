import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../bloc/canvas_bloc.dart';

/// SVG contour layer on top of the drawing.
class ContourLayer extends StatelessWidget {
  /// Creates a [ContourLayer].
  const ContourLayer({super.key});

  @override
  Widget build(BuildContext context) {
    final CanvasState state = context.watch<CanvasBloc>().state;
    if (state.contour == null) return const SizedBox.shrink();

    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: state.contourOpacity,
          child: SvgPicture.string(
            SvgUtils.applyStrokeWidth(
              state.contour!.svgData,
              state.contourWidth,
            ),
            colorFilter: ColorFilter.mode(
              state.contourColor,
              BlendMode.srcIn,
            ),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
