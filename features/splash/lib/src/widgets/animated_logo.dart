import 'dart:async';

import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Animated logo widget for the splash screen.
///
/// Features a logo with an appearing shadow and a continuous shimmering
/// effect on the brand text, acting as a minimalist loading indicator.
class AnimatedLogo extends StatefulWidget {
  /// Callback invoked when the initial animation sequence completes.
  /// Subsequent loops do not trigger this.
  final VoidCallback onFinished;

  /// Creates an [AnimatedLogo].
  const AnimatedLogo({
    required this.onFinished,
    super.key,
  });

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _shimmerAnimation;

  bool _showShadow = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.linear),
      ),
    );

    _startAnimation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startAnimation() async {
    // 1. Start shadow animation
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    setState(() => _showShadow = true);

    // 2. Start infinite shimmering loop
    _controller.repeat();

    // 3. Wait for a moment to notify that the screen is "stable"
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeInOut,
          opacity: _showShadow ? 1.0 : 0.0,
          child: SvgPicture.asset(
            AppImages.logo,
            package: AppImages.packageName,
            width: 80,
            height: 80,
          ),
        ),
        const SizedBox(height: 32),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: const [0.0, 0.5, 1.0],
                  colors: [
                    colors.accentDark,
                    colors.accentLight,
                    colors.accentDark,
                  ],
                  transform: _SlidingGradientTransform(
                    percent: _shimmerAnimation.value,
                  ),
                ).createShader(bounds);
              },
              child: child,
            );
          },
          child: SvgPicture.asset(
            AppImages.logoText,
            package: AppImages.packageName,
            width: 200,
            colorFilter: ColorFilter.mode(
              colors.accentDark,
              BlendMode.srcIn,
            ),
          ),
        ),
      ],
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({
    required this.percent,
  });

  final double percent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * percent, 0, 0);
  }
}
