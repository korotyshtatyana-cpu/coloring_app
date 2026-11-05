import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

/// Blocking scrim shown while a rewarded ad is being loaded.
class AdLoadingOverlay extends StatelessWidget {
  /// Creates an [AdLoadingOverlay].
  const AdLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return ColoredBox(
      color: colors.black.withValues(alpha: 0.4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: colors.secondaryBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CircularProgressIndicator(color: colors.accentDark),
              const SizedBox(height: 12),
              Text(
                LocaleKeys.rewarded_ad_loading.tr(),
                style: AppFonts.normal16.copyWith(color: colors.primaryText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
