import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:feedback/feedback.dart';
import 'package:flutter/material.dart';

import 'feedback_button.dart';

class FeedbackActions extends StatelessWidget {
  final String? email;

  const FeedbackActions({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FeedbackButton(
          icon: Icons.star_rate_rounded,
          label: LocaleKeys.rate_the_app.tr(),
          onPressed: () => _showRateDialog(context),
        ),
        FeedbackButton(
          icon: Icons.bug_report_rounded,
          label: LocaleKeys.report_a_problem.tr(),
          onPressed: () =>
              _showFeedbackForm(context, FeedbackType.bug, email ?? ''),
        ),
        FeedbackButton(
          icon: Icons.lightbulb_rounded,
          label: LocaleKeys.suggest_an_idea.tr(),
          onPressed: () =>
              _showFeedbackForm(context, FeedbackType.feature, email ?? ''),
        ),
      ],
    );
  }

  void _showRateDialog(BuildContext context) {
    final colors = AppColors.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.secondaryBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(LocaleKeys.rate_the_app.tr(), style: AppFonts.semiBold20),
        content: Text(
          LocaleKeys.rate_the_app_message.tr(),
          style: AppFonts.normal16,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                text: LocaleKeys.cancel.tr(),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 12),
              AppButton(
                text: LocaleKeys.go_to_store.tr(),
                filled: true,
                onPressed: () {
                  Navigator.of(context).pop();
                  UrlUtils.openStoreListing();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFeedbackForm(
    BuildContext context,
    FeedbackType type,
    String email,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.of(context).primaryBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: FeedbackForm(type: type, initialEmail: email),
      ),
    );
  }
}
