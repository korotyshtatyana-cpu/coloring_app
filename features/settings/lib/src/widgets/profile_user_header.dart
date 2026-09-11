import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

/// Header widget for the profile screen showing user avatar and name.
class ProfileUserHeader extends StatefulWidget {
  /// Authenticated user information.
  final UserEntity? user;

  /// Creates a [ProfileUserHeader].
  const ProfileUserHeader({required this.user, super.key});

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

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: colors.accentDark, width: 3.0),
            boxShadow: [
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
        const SizedBox(height: 16),
        Text(
          LocaleKeys.hi_user.tr(
            args: [widget.user?.name ?? LocaleKeys.user_placeholder.tr()],
          ),
          textAlign: TextAlign.center,
          style: AppFonts.semiBold24.copyWith(color: colors.primaryText),
        ),
      ],
    );
  }
}
