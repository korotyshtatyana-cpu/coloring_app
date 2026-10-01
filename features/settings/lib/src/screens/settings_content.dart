import 'dart:io';

import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

import '../bloc/settings_bloc.dart';
import '../widgets/feedback/feedback_actions.dart';
import '../widgets/language_picker.dart';
import '../widgets/profile_user_header.dart';

/// UI implementation of the settings screen (Profile).
class SettingsContent extends StatelessWidget {
  /// Creates [SettingsContent].
  const SettingsContent({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    final SettingsState state = context.watch<SettingsBloc>().state;

    return Scaffold(
      backgroundColor: colors.primaryBg,
      appBar: AppBar(
        centerTitle: false,
        toolbarHeight: 68,
        leadingWidth: 64,
        backgroundColor: colors.primaryBg,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16, top: 10, bottom: 10),
          child: ToolbarContainer(
            backgroundColor: colors.accentDark,
            isSquare: true,
            child: AppIconButton(
              size: 32,
              iconSize: 24,
              icon: Icon(Icons.arrow_back, color: colors.primaryBg),
              backgroundColor: Colors.transparent,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: Text(
          LocaleKeys.profile.tr(),
          style: AppFonts.appBarTitle.copyWith(
            color: colors.primaryText,
            shadows: [],
          ),
        ),
      ),
      body: BlocListener<SettingsBloc, SettingsState>(
        listenWhen: (prev, curr) =>
            prev.isDeleted != curr.isDeleted && curr.isDeleted,
        listener: (context, state) {
          // Close the app after successful deletion
          exit(0);
        },
        child: BlocListener<SettingsBloc, SettingsState>(
          listenWhen: (prev, curr) => prev.status != curr.status,
          listener: (context, state) {
            if (state.status == SettingsStatus.failure) {
              ErrorDialog.show(
                context,
                message: state.error ?? LocaleKeys.something_went_wrong.tr(),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                // 1. User Header
                ProfileUserHeader(user: state.user),
                const SizedBox(height: 24),
                Divider(height: 1, thickness: 1, color: colors.accentLight),
                const SizedBox(height: 24),

                // 2. Language Selection
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocaleKeys.language.tr(),
                        style: AppFonts.semiBold20.copyWith(
                          color: colors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const LanguagePicker(),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Divider(height: 1, thickness: 1, color: colors.accentLight),
                const SizedBox(height: 24),

                // 3. Feedback Actions
                FeedbackActions(email: state.user?.email),
                const SizedBox(height: 24),
                Divider(height: 1, thickness: 1, color: colors.accentLight),

                // 4. Delete Account
                const Spacer(),
                AppButton(
                  text: LocaleKeys.delete_account.tr(),
                  color: Colors.redAccent,
                  onPressed: () => _showDeleteConfirmation(context),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final bloc = context.read<SettingsBloc>();
    final colors = AppColors.of(context);

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: colors.secondaryBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            LocaleKeys.delete_account_confirm_title.tr(),
            style: AppFonts.semiBold20.copyWith(color: colors.primaryText),
          ),
          content: Text(
            LocaleKeys.delete_account_confirm_message.tr(),
            style: AppFonts.normal16.copyWith(color: colors.primaryText),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton(
                  text: LocaleKeys.cancel.tr(),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 12),
                AppButton(
                  text: LocaleKeys.confirm.tr(),
                  filled: true,
                  color: Colors.redAccent,
                  onPressed: () {
                    bloc.add(const DeleteAccount());
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
