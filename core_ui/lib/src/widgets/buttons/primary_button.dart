import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_fonts.dart';

/// Primary rounded button used throughout the application.
class PrimaryButton extends StatelessWidget {
  /// Button label text.
  final String text;

  /// Callback invoked when the button is pressed.
  final VoidCallback? onPressed;

  /// Whether to show a loading indicator instead of the label.
  final bool isLoading;

  /// Optional fixed width.
  final double? width;

  /// Optional fixed height.
  final double? height;

  /// Creates a [PrimaryButton].
  const PrimaryButton({
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.width,
    this.height,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.secondaryBg,
          foregroundColor: colors.primaryBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.defaultBorder),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 24,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.primaryBg,
                ),
              )
            : Text(
                text,
                style: AppFonts.semiBold20.copyWith(color: colors.primaryBg),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
      ),
    );
  }
}
