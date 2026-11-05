import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Small badge shown in the top-right corner of a gallery card.
///
/// Renders nothing while [access] is `null` (the monetization status has not
/// resolved yet) and for [ProjectAccess.unlocked] projects, so the badge fades
/// in only where the user still has to act to open the project.
class ProjectAccessBadge extends StatelessWidget {
  /// Access level resolved for the contour, or `null` while it is loading.
  final ProjectAccess? access;

  /// Access type of the contour, which selects the icon for
  /// [ProjectAccess.locked].
  final ContourAccessType accessType;

  /// Creates a [ProjectAccessBadge].
  const ProjectAccessBadge({
    required this.access,
    required this.accessType,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final Widget child = _buildIcon(context, colors);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeIn,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: child,
    );
  }

  Widget _buildIcon(BuildContext context, AppColors colors) {
    final bool isLocked = access == ProjectAccess.locked;

    final Color backgroundColor = switch (accessType) {
      ContourAccessType.rewarded when isLocked => colors.averagePurple,
      ContourAccessType.paid when isLocked => colors.premiumGold,
      _ => colors.secondaryBg,
    };

    final Widget? icon = _resolveIcon(colors, isLocked);
    if (icon == null) {
      return const SizedBox.shrink(key: ValueKey<String>('access-badge-empty'));
    }

    return Container(
      key: const ValueKey<String>('access-badge'),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(8)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.accentDark.withValues(alpha: 0.3),
            blurRadius: 4,
          ),
        ],
      ),
      child: icon,
    );
  }

  Widget? _resolveIcon(AppColors colors, bool isLocked) {
    if (access == ProjectAccess.viewOnly) {
      return _svgIcon(AppImages.readOnly, colors.iconPrimary);
    }
    if (!isLocked) {
      return null;
    }

    return switch (accessType) {
      ContourAccessType.free => null,
      ContourAccessType.rewarded => _svgIcon(AppImages.rewarded, colors.white),
      ContourAccessType.paid => _svgIcon(AppImages.paid, colors.black),
    };
  }

  Widget _svgIcon(String asset, Color color) {
    return SvgPicture.asset(
      asset,
      package: AppImages.packageName,
      width: 16,
      height: 16,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
