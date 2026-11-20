import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../../utils/color_format.dart';

/// Bottom row with recent color swatches and an eyedropper button.
class RecentColorsRow extends StatelessWidget {
  /// Creates the row with [colors] ordered from newest to oldest.
  const RecentColorsRow({
    required this.colors,
    required this.onSelected,
    required this.onEyedropper,
    super.key,
  });

  /// Number of swatches visible in the row.
  ///
  /// Matches [RecentColorsService.maxColors], so every saved color is shown.
  static const int displayedCount = RecentColorsService.maxColors;

  /// Saved colors in `#RRGGBB` form, newest first.
  final List<String> colors;

  /// Called when the user taps one of the saved colors.
  final ValueChanged<String> onSelected;

  /// Called when the user taps the eyedropper button.
  final VoidCallback onEyedropper;

  @override
  Widget build(BuildContext context) {
    final AppColors palette = AppColors.of(context);
    final BorderSide border = BorderSide(
      color: palette.primaryText.withValues(alpha: 0.4),
      width: 1,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 0),
          child: Text(
            LocaleKeys.recent.tr(),
            style: AppFonts.normal16.copyWith(color: palette.primaryText),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Row(
              children: List<Widget>.generate(displayedCount, (int index) {
                final String? hex = index < colors.length
                    ? colors[index]
                    : null;
                final Color? color = hex == null
                    ? null
                    : ColorFormat.tryParseHex(hex);
                return Padding(
                  padding: EdgeInsets.only(
                    right: index == displayedCount - 1 ? 0 : 3,
                  ),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: Material(
                      color: color ?? palette.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(5),
                        ),
                        side: border,
                      ),
                      child: InkWell(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(5),
                        ),
                        onTap: hex == null ? null : () => onSelected(hex),
                      ),
                    ),
                  ),
                );
              }),
            ),
            IconButton(
              icon: Icon(Icons.colorize, color: palette.iconPrimary, size: 20),
              tooltip: LocaleKeys.eyedropper.tr(),
              onPressed: onEyedropper,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ],
    );
  }
}
