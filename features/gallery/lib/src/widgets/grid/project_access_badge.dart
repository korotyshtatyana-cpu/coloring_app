import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

/// Small badge shown in the bottom-right corner of a gallery card.
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
  const ProjectAccessBadge({required this.access, required this.accessType, super.key});

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
    final IconData? iconData = _resolveIcon();
    if (iconData == null) {
      return const SizedBox.shrink(key: ValueKey<String>('access-badge-empty'));
    }

    return Container(
      key: const ValueKey<String>('access-badge'),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.secondaryBg.withValues(alpha: 0.92),
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(color: colors.accentDark.withValues(alpha: 0.3), blurRadius: 4),
        ],
      ),
      child: Icon(iconData, size: 16, color: colors.iconPrimary),
    );
  }

  IconData? _resolveIcon() {
    if (access == ProjectAccess.viewOnly) {
      return Icons.visibility_outlined;
    }
    if (access != ProjectAccess.locked) {
      return null;
    }

    switch (accessType) {
      case ContourAccessType.free:
        return null;
      case ContourAccessType.rewarded:
        return Icons.play_circle_outline;
      case ContourAccessType.paid:
        return Icons.lock_outline;
    }
  }
}
