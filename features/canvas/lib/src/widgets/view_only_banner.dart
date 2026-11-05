import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../bloc/canvas_bloc.dart';

/// Banner shown when the project is view-only.
///
/// Styled like the canvas control panels ([ToolbarContainer]) and ignores
/// pointer events so it never blocks panning or zooming the artwork. The
/// message reflects [reason] when the canvas switched to view-only while it
/// was open.
class ViewOnlyBanner extends StatelessWidget {
  /// Why the canvas lost editing access, or `null` when the project was
  /// opened read-only from the start.
  final ViewOnlyReason? reason;

  /// Callback invoked when the user taps "Unlock Access" to open the purchase dialog.
  final VoidCallback? onUnlockPressed;

  /// Creates a [ViewOnlyBanner].
  const ViewOnlyBanner({
    this.reason,
    this.onUnlockPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return Center(
      child: ToolbarContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SvgPicture.asset(
                  AppImages.readOnly,
                  package: AppImages.packageName,
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(
                    colors.iconPrimary,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _message(),
                    textAlign: TextAlign.center,
                    style: AppFonts.normal16.copyWith(
                      color: colors.primaryText,
                    ),
                  ),
                ),
              ],
            ),
            if (onUnlockPressed != null) ...<Widget>[
              const SizedBox(height: 10),
              AppButton(
                text: LocaleKeys.view_only_unlock_access.tr(),
                onPressed: onUnlockPressed,
                filled: true,
                color: colors.premiumGold,
                shrinkWrap: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _message() {
    return switch (reason) {
      ViewOnlyReason.refunded => LocaleKeys.canvas_refund_banner.tr(),
      ViewOnlyReason.subscriptionExpired =>
        LocaleKeys.canvas_subscription_expired_banner.tr(),
      null => LocaleKeys.view_only_message.tr(),
    };
  }
}
