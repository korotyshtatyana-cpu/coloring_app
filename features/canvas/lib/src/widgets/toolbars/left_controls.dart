import 'package:flutter/material.dart';

import 'left_controls/single_column_layout.dart';
import 'left_controls/two_columns_layout.dart';
import 'toolbar_container.dart';

/// Left-side control panel with brush size, opacity and view reset.
///
/// On tall screens the controls are laid out in a single column; when the
/// available height is too small (e.g. a phone in portrait) they wrap into
/// two columns so every control stays visible.
class LeftControls extends StatelessWidget {
  /// Creates [LeftControls].
  const LeftControls({super.key});

  @override
  Widget build(BuildContext context) {
    // Fixed heights so the required panel height is predictable.
    const double iconButtonSize = 32;
    const double gap = 8;
    const double sliderHeight = 160;
    const double singleColumnHeight =
        2 * iconButtonSize + 2 * gap + 2 * sliderHeight + gap + iconButtonSize;

    // Vertical space available to the panel: from its top position (120) up
    // to the bottom edge, minus system bars.
    final MediaQueryData mq = MediaQuery.of(context);
    final double availableHeight = mq.size.height -
        mq.viewPadding.top -
        mq.viewPadding.bottom -
        8;

    // Constrain the panel so it can never overflow, and let LayoutBuilder
    // pick the layout based on the real, bounded height.
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: availableHeight),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool useTwoColumns = singleColumnHeight > constraints.maxHeight;
          return ToolbarContainer(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
            child: useTwoColumns
                ? const TwoColumnsLayout(
                    iconButtonSize: iconButtonSize,
                    gap: gap,
                    sliderHeight: sliderHeight,
                  )
                : const SingleColumnLayout(
                    iconButtonSize: iconButtonSize,
                    gap: gap,
                    sliderHeight: sliderHeight,
                  ),
          );
        },
      ),
    );
  }
}
