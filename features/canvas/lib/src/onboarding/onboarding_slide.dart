import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

/// Single slide item in the canvas onboarding dialog.
class OnboardingSlide extends StatelessWidget {
  /// Localized title key for the slide.
  final String titleKey;

  /// Localized description/text key for the slide.
  final String textKey;

  /// Creates an [OnboardingSlide].
  const OnboardingSlide({
    required this.titleKey,
    required this.textKey,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const SizedBox(height: 8),
          Flexible(
            child: Image.asset(
              AppImages.appIcon,
              package: AppImages.packageName,
              height: 160,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            titleKey.tr(),
            style: AppFonts.smallTitle.copyWith(color: colors.primaryText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            textKey.tr(),
            style: AppFonts.normal12.copyWith(
              color: colors.primaryText.withValues(alpha: 0.8),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
