import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

/// App title widget for the splash screen.
class SplashTitle extends StatelessWidget {
  /// Creates a [SplashTitle].
  const SplashTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return Text(
      LocaleKeys.app_title.tr(),
      style: AppFonts.extraBold46.copyWith(color: colors.primaryText),
    );
  }
}
