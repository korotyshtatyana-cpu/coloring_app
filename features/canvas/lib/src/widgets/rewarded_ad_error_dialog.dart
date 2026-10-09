import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

/// Modal shown when the user does not finish watching a rewarded ad.
///
/// Returns `true` when the user wants to retry, `false` when they cancel.
class RewardedAdErrorDialog extends StatelessWidget {
  /// Creates a [RewardedAdErrorDialog].
  const RewardedAdErrorDialog({super.key});

  /// Shows the dialog and returns whether the user chose to retry.
  static Future<bool> show(BuildContext context) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => const RewardedAdErrorDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return AlertDialog(
      backgroundColor: colors.secondaryBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        LocaleKeys.rewarded_ad_not_completed_title.tr(),
        style: AppFonts.semiBold20.copyWith(color: colors.primaryText),
      ),
      content: Text(
        LocaleKeys.rewarded_ad_not_completed_text.tr(),
        style: AppFonts.normal16.copyWith(color: colors.primaryText),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            AppButton(
              text: LocaleKeys.rewarded_ad_cancel.tr(),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            const SizedBox(width: 12),
            AppButton(
              text: LocaleKeys.rewarded_ad_retry.tr(),
              filled: true,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ],
    );
  }
}
