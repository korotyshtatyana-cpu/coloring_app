import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

/// Header widget for the profile screen showing user avatar and name.
///
/// The avatar frame reflects the subscription status: gray without a plan,
/// purple with an `AD` mark for No Ads, gold with a crown for Premium.
class ProfileUserHeader extends StatefulWidget {
  /// Authenticated user information.
  final UserEntity? user;

  /// Active subscription plan, or `null` when there is no active plan.
  final SubscriptionPlanType? planType;

  /// Whether the user permanently owns the No Ads plan.
  final bool noAdsPurchased;

  /// Creates a [ProfileUserHeader].
  const ProfileUserHeader({
    required this.user,
    this.planType,
    this.noAdsPurchased = false,
    super.key,
  });

  @override
  State<ProfileUserHeader> createState() => _ProfileUserHeaderState();
}

class _ProfileUserHeaderState extends State<ProfileUserHeader> {
  bool _avatarLoadFailed = false;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final String? avatarUrl = widget.user?.avatarUrl;
    final bool hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    final bool showImage = hasAvatar && !_avatarLoadFailed;

    final bool isPremium = widget.planType == SubscriptionPlanType.premium;
    final bool isNoAds =
        widget.planType == SubscriptionPlanType.noAds ||
        widget.noAdsPurchased;

    final Color frameColor;
    final Widget? badge;
    if (isPremium) {
      frameColor = colors.premiumGold;
      badge = _FrameBadge(
        color: colors.premiumGold,
        child: Icon(Icons.workspace_premium, size: 16, color: colors.black),
      );
    } else if (isNoAds) {
      frameColor = colors.averagePurple;
      badge = _FrameBadge(
        color: colors.averagePurple,
        child: Text(
          'AD',
          style: AppFonts.normal10.copyWith(
            color: colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    } else {
      frameColor = colors.accentLight;
      badge = null;
    }

    return Column(
      children: <Widget>[
        Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: frameColor, width: 3.0),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: colors.secondaryBg,
                backgroundImage: showImage ? NetworkImage(avatarUrl) : null,
                onBackgroundImageError: showImage
                    ? (_, __) => setState(() => _avatarLoadFailed = true)
                    : null,
                child: showImage
                    ? null
                    : Icon(Icons.person, color: colors.iconPrimary, size: 40),
              ),
            ),
            if (badge != null)
              Positioned(right: 0, bottom: 0, child: badge),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          LocaleKeys.hi_user.tr(
            args: <String>[
              widget.user?.name ?? LocaleKeys.user_placeholder.tr(),
            ],
          ),
          textAlign: TextAlign.center,
          style: AppFonts.semiBold24.copyWith(color: colors.primaryText),
        ),
      ],
    );
  }
}

class _FrameBadge extends StatelessWidget {
  final Color color;
  final Widget child;

  const _FrameBadge({required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: child,
    );
  }
}
