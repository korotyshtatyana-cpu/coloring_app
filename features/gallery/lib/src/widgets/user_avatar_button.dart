import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

/// App bar button showing the current user's avatar.
///
/// The avatar is taken from the auth account (Supabase user metadata).
/// When the user is not signed in or has no avatar, a default person icon
/// is shown instead.
class UserAvatarButton extends StatefulWidget {
  /// Called when the button is tapped.
  final VoidCallback onPressed;

  /// Creates a [UserAvatarButton].
  const UserAvatarButton({required this.onPressed, super.key});

  @override
  State<UserAvatarButton> createState() => _UserAvatarButtonState();
}

class _UserAvatarButtonState extends State<UserAvatarButton> {
  UserEntity? _user;
  bool _avatarLoadFailed = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final UserEntity? user = await appLocator<GetCurrentUserUseCase>()
          .execute();
      if (mounted) {
        setState(() => _user = user);
      }
    } catch (_) {
      // No session or offline: the default icon is shown.
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final String? avatarUrl = _user?.avatarUrl;
    final bool hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    final bool showImage = hasAvatar && !_avatarLoadFailed;

    return GestureDetector(
      onTap: widget.onPressed,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: colors.accentDark,
            width: 2.0,
          ),
        ),
        child: CircleAvatar(
          radius: 16,
          backgroundColor: colors.secondaryBg,
          backgroundImage: showImage ? NetworkImage(avatarUrl) : null,
          onBackgroundImageError: showImage
              ? (_, __) => setState(() => _avatarLoadFailed = true)
              : null,
          child: showImage
              ? null
              : Icon(Icons.person, color: colors.primaryText, size: 20),
        ),
      ),
    );
  }
}