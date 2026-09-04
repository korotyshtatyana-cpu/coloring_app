import 'package:flutter/material.dart';

import 'brush_button.dart';
import 'brush_size_slider.dart';
import 'eraser_button.dart';
import 'opacity_slider.dart';
import 'reset_view_button.dart';

/// Two columns layout for left controls.
class TwoColumnsLayout extends StatelessWidget {
  /// Height of icon buttons.
  final double iconButtonSize;

  /// Gap between elements.
  final double gap;

  /// Height of sliders.
  final double sliderHeight;

  /// Creates a [TwoColumnsLayout].
  const TwoColumnsLayout({
    required this.iconButtonSize,
    required this.gap,
    required this.sliderHeight,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            BrushButton(size: iconButtonSize),
            SizedBox(height: gap),
            BrushSizeSlider(height: sliderHeight),
            ResetViewButton(size: iconButtonSize),
          ],
        ),
        SizedBox(width: gap),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            EraserButton(size: iconButtonSize),
            SizedBox(height: gap),
            OpacitySlider(height: sliderHeight),
          ],
        ),
      ],
    );
  }
}
