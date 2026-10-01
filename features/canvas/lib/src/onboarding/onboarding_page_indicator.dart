import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

/// Animated page indicator dots for the canvas onboarding dialog.
class OnboardingPageIndicator extends StatelessWidget {
  /// Total number of pages.
  final int count;

  /// Currently active page index.
  final int currentIndex;

  /// Creates an [OnboardingPageIndicator].
  const OnboardingPageIndicator({
    required this.count,
    required this.currentIndex,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(count, (int index) {
        final bool isSelected = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isSelected ? 16 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isSelected ? colors.accentDark : colors.accentLight,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
