import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

/// Single slide item in the canvas onboarding dialog.
class OnboardingSlide extends StatelessWidget {
  /// Localized title key for the slide.
  final String titleKey;

  /// Localized description/text key for the slide.
  final String textKey;

  /// Image asset path for the slide.
  final String imagePath;

  /// Creates an [OnboardingSlide].
  const OnboardingSlide({
    required this.titleKey,
    required this.textKey,
    required this.imagePath,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final Orientation orientation = MediaQuery.orientationOf(context);
    final bool isLandscape = orientation == Orientation.landscape;

    if (isLandscape) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Flexible(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  imagePath,
                  package: AppImages.packageName,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    titleKey.tr(),
                    style: AppFonts.semiBold20.copyWith(
                      color: colors.primaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    textKey.tr(),
                    softWrap: true,
                    style: AppFonts.normal14.copyWith(
                      color: colors.primaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Flexible(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                imagePath,
                package: AppImages.packageName,
                height: 300,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            titleKey.tr(),
            style: AppFonts.semiBold20.copyWith(color: colors.primaryText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            textKey.tr(),
            softWrap: true,
            style: AppFonts.normal14.copyWith(color: colors.primaryText),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
