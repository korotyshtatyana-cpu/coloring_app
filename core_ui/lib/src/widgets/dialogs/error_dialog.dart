import 'package:core/core.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../buttons/primary_button.dart';

/// Error dialog with a title, message and retry action.
class ErrorDialog extends StatelessWidget {
  /// Dialog title.
  final String title;

  /// Error message.
  final String message;

  /// Retry button label.
  final String retryLabel;

  /// Callback invoked when retry is pressed.
  final VoidCallback? onRetry;

  /// Creates an [ErrorDialog].
  const ErrorDialog({
    required this.title,
    required this.message,
    this.retryLabel = 'Retry',
    this.onRetry,
    super.key,
  });

  /// Shows an error dialog with the given [message].
  static Future<void> show(
    BuildContext context, {
    String? title,
    required String message,
    String? retryLabel,
    VoidCallback? onRetry,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return ErrorDialog(
          title: title ?? LocaleKeys.error.tr(context: context),
          message: message,
          retryLabel: retryLabel ?? LocaleKeys.retry.tr(context: context),
          onRetry: onRetry,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return AlertDialog(
      backgroundColor: colors.secondaryBg,
      title: Text(
        title,
        style: AppFonts.semiBold20.copyWith(color: colors.accentDark),
      ),
      content: Text(
        message,
        style: AppFonts.normal16.copyWith(color: colors.primaryText),
      ),
      actions: <Widget>[
          PrimaryButton(
            text: onRetry == null ? LocaleKeys.ok.tr() : retryLabel,
            onPressed: onRetry ?? () => Navigator.of(context).pop(),
          ),
      ],
    );
  }
}
