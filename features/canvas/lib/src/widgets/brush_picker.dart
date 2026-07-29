import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/canvas_bloc.dart';

/// Maps each brush type to a placeholder icon.
IconData _brushIcon(BrushType type) {
  return switch (type) {
    BrushType.circle => Icons.circle_outlined,
    BrushType.square => Icons.square_outlined,
    BrushType.watercolor => Icons.water_drop_outlined,
    BrushType.chalk => Icons.grain,
    BrushType.marker => Icons.edit,
    BrushType.calligraphy => Icons.brush,
    BrushType.texture => Icons.texture,
    BrushType.airbrush => Icons.cloud,
  };
}

/// Brush picker grid for selecting a brush type.
class BrushPicker extends StatelessWidget {
  /// Creates a [BrushPicker].
  const BrushPicker({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final BrushType activeType = context.select(
      (CanvasBloc bloc) => bloc.state.brushType,
    );

    return Container(
      color: colors.secondaryBg,
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        shrinkWrap: true,
        children: BrushType.values.map((BrushType type) {
          final isActive = type == activeType;
          return InkWell(
            onTap: () => context.read<CanvasBloc>().add(ChangeBrushType(type)),
            child: Container(
              decoration: BoxDecoration(
                color: isActive ? colors.primaryBg : colors.secondaryBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive ? colors.primaryBg : colors.primaryText,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    _brushIcon(type),
                    color: isActive ? colors.secondaryBg : colors.primaryText,
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    type.name,
                    style: AppFonts.normal14.copyWith(
                      color: isActive ? colors.secondaryBg : colors.primaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
