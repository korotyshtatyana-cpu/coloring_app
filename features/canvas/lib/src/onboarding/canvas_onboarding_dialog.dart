import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import 'onboarding_page_indicator.dart';
import 'onboarding_slide.dart';

/// Displays the canvas onboarding dialog.
///
/// If [forceShow] is false, checks if the onboarding was already shown using
/// [CheckCanvasOnboardingShownUseCase]. If [forceShow] is true or it was not
/// shown yet, presents the onboarding dialog.
Future<void> showCanvasOnboarding(
  BuildContext context, {
  bool forceShow = false,
}) async {
  if (!forceShow) {
    final bool isShown = await appLocator<CheckCanvasOnboardingShownUseCase>()
        .execute();
    if (isShown) return;
  }

  if (!context.mounted) return;

  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'CanvasOnboarding',
    barrierColor: Colors.black.withValues(alpha: 0.5),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return const CanvasOnboardingDialog();
    },
  );
}

/// Onboarding dialog displaying a 10-slide tutorial for the canvas screen.
class CanvasOnboardingDialog extends StatefulWidget {
  /// Creates a [CanvasOnboardingDialog].
  const CanvasOnboardingDialog({super.key});

  @override
  State<CanvasOnboardingDialog> createState() => _CanvasOnboardingDialogState();
}

class _CanvasOnboardingDialogState extends State<CanvasOnboardingDialog> {
  late final PageController _pageController;
  int _currentIndex = 0;

  static const List<({String titleKey, String textKey})> _slides = [
    (
      titleKey: LocaleKeys.onboarding_slide1_title,
      textKey: LocaleKeys.onboarding_slide1_text,
    ),
    (
      titleKey: LocaleKeys.onboarding_slide2_title,
      textKey: LocaleKeys.onboarding_slide2_text,
    ),
    (
      titleKey: LocaleKeys.onboarding_slide3_title,
      textKey: LocaleKeys.onboarding_slide3_text,
    ),
    (
      titleKey: LocaleKeys.onboarding_slide4_title,
      textKey: LocaleKeys.onboarding_slide4_text,
    ),
    (
      titleKey: LocaleKeys.onboarding_slide5_title,
      textKey: LocaleKeys.onboarding_slide5_text,
    ),
    (
      titleKey: LocaleKeys.onboarding_slide6_title,
      textKey: LocaleKeys.onboarding_slide6_text,
    ),
    (
      titleKey: LocaleKeys.onboarding_slide7_title,
      textKey: LocaleKeys.onboarding_slide7_text,
    ),
    (
      titleKey: LocaleKeys.onboarding_slide8_title,
      textKey: LocaleKeys.onboarding_slide8_text,
    ),
    (
      titleKey: LocaleKeys.onboarding_slide9_title,
      textKey: LocaleKeys.onboarding_slide9_text,
    ),
    (
      titleKey: LocaleKeys.onboarding_slide10_title,
      textKey: LocaleKeys.onboarding_slide10_text,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _closeDialog() async {
    await appLocator<SetCanvasOnboardingShownUseCase>().execute();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _onPrevPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onNextPage() {
    if (_currentIndex < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _closeDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return PopScope(
      onPopInvokedWithResult: (bool didPop, Object? result) {
        appLocator<SetCanvasOnboardingShownUseCase>().execute();
      },
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.primaryBg,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, color: colors.iconPrimary),
                      onPressed: _closeDialog,
                    ),
                  ],
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    onPageChanged: (int index) {
                      setState(() => _currentIndex = index);
                    },
                    itemBuilder: (BuildContext context, int index) {
                      final slide = _slides[index];
                      return OnboardingSlide(
                        titleKey: slide.titleKey,
                        textKey: slide.textKey,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                OnboardingPageIndicator(
                  count: _slides.length,
                  currentIndex: _currentIndex,
                ),
                const SizedBox(height: 24),
                Row(
                  children: <Widget>[
                    AppButton(
                      onPressed: _closeDialog,
                      text: LocaleKeys.onboarding_skip.tr(),
                    ),
                    const Spacer(),
                    if (_currentIndex > 0) ...{
                      Expanded(
                        child: AppButton(
                          onPressed: _onPrevPage,
                          text: LocaleKeys.onboarding_back.tr(),
                        ),
                      ),
                    } else ...{
                      const Spacer(),
                    },
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        filled: true,
                        color: colors.accentDark,
                        text: _currentIndex == _slides.length - 1
                            ? LocaleKeys.onboarding_start.tr()
                            : LocaleKeys.onboarding_next.tr(),
                        onPressed: _onNextPage,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
