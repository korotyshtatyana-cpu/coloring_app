import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';

/// Custom rounded button used throughout the app, e.g. inside dialogs.
///
/// By default the button is outlined (transparent background with a colored
/// border, like the delete account button). Set [filled] to true for the
/// filled variant.
///
/// The button is disabled when [onPressed] is null; a disabled button is
/// rendered in [AppColors.iconDisabled] instead of [color].
class AppButton extends StatelessWidget {
  /// Button label text.
  final String text;

  /// Callback invoked when the button is pressed. The button is disabled
  /// when this is null.
  final VoidCallback? onPressed;

  /// Whether the button is filled with [color]. When false (default), the
  /// button is outlined.
  final bool filled;

  /// Accent color of the button: border and text when outlined, background
  /// when filled. Defaults to [AppColors.iconPrimary] when outlined and to
  /// [AppColors.accentDark] when filled. Disabled buttons use
  /// [AppColors.iconDisabled] instead.
  final Color? color;

  /// Creates an [AppButton].
  const AppButton({
    required this.text,
    required this.onPressed,
    this.filled = false,
    this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final bool isDisabled = onPressed == null;
    final Color effectiveColor = isDisabled
        ? colors.iconDisabled
        : color ?? (filled ? colors.accentDark : colors.iconPrimary);
    final Color textColor = filled ? colors.primaryBg : effectiveColor;

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: textColor,
        backgroundColor: filled ? effectiveColor : Colors.transparent,
        // styleFrom falls back to the theme's disabled colors unless these
        // are passed explicitly.
        disabledForegroundColor: textColor,
        disabledBackgroundColor:
            filled ? effectiveColor : Colors.transparent,
        side: filled ? null : BorderSide(color: effectiveColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
      ),
      child: Text(
        text,
        style: AppFonts.normal14.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
