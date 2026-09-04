import 'package:flutter/material.dart';

import 'brush_button.dart';
import 'brush_size_slider.dart';
import 'eraser_button.dart';
import 'opacity_slider.dart';
import 'reset_view_button.dart';

/// Single column layout for left controls.
class SingleColumnLayout extends StatelessWidget {
  /// Height of icon buttons.
  final double iconButtonSize;

  /// Gap between elements.
  final double gap;

  /// Height of sliders.
  final double sliderHeight;

  /// Creates a [SingleColumnLayout].
  const SingleColumnLayout({
    required this.iconButtonSize,
    required this.gap,
    required this.sliderHeight,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        BrushButton(size: iconButtonSize),
        SizedBox(height: gap),
        EraserButton(size: iconButtonSize),
        SizedBox(height: gap),
        BrushSizeSlider(height: sliderHeight),
        OpacitySlider(height: sliderHeight),
        SizedBox(height: gap),
        ResetViewButton(size: iconButtonSize),
      ],
    );
  }
}
