import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';

/// Loading dialog with a circular progress indicator and optional message.
class LoadingDialog extends StatelessWidget {
  /// Optional message displayed under the indicator.
  final String? message;

  /// Creates a [LoadingDialog].
  const LoadingDialog({this.message, super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return Dialog(
      backgroundColor: colors.secondaryBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircularProgressIndicator(color: colors.primaryBg),
            if (message != null) ...<Widget>[
              const SizedBox(height: 16),
              Text(
                message!,
                style: AppFonts.normal16.copyWith(color: colors.primaryText),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
