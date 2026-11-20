import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

import '../../bloc/canvas_bloc.dart';
import '../../utils/color_format.dart';
import '../../utils/marker_colors.dart';

/// Scrollable grid of the flat marker color library.
class LibraryTab extends StatelessWidget {
  /// Creates the library grid.
  const LibraryTab({
    required this.isContour,
    required this.onColorSelected,
    super.key,
  });

  /// Whether the picker edits the contour color instead of the brush color.
  final bool isContour;

  /// Called with the color of the tapped square.
  final ValueChanged<Color> onColorSelected;

  @override
  Widget build(BuildContext context) {
    final AppColors palette = AppColors.of(context);
    final Color selectedColor = context.select(
      (CanvasBloc bloc) =>
          isContour ? bloc.state.contourColor : bloc.state.color,
    );
    final int selectedRgb = selectedColor.toARGB32() & 0xFFFFFF;
    final BorderSide regularBorder = BorderSide(
      color: palette.primaryText.withValues(alpha: 0.35),
      width: 1,
    );
    final BorderSide selectedBorder = BorderSide(
      color: palette.accentDark,
      width: 2,
    );

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1,
      ),
      itemCount: MarkerColors.hexValues.length,
      itemBuilder: (BuildContext context, int index) {
        final Color color = ColorFormat.tryParseHex(
          MarkerColors.hexValues[index],
        )!;
        final bool isSelected = (color.toARGB32() & 0xFFFFFF) == selectedRgb;
        return Material(
          color: color,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(6)),
            side: isSelected ? selectedBorder : regularBorder,
          ),
          child: InkWell(
            borderRadius: const BorderRadius.all(Radius.circular(6)),
            onTap: () => onColorSelected(color),
          ),
        );
      },
    );
  }
}
