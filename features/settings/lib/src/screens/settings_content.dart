import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

import '../bloc/settings_bloc.dart';
import '../widgets/language_picker.dart';

/// UI implementation of the settings screen.
class SettingsContent extends StatelessWidget {
  /// Creates [SettingsContent].
  const SettingsContent({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final TextStyle sectionHeaderStyle = AppFonts.semiBold20.copyWith(color: colors.primaryText);

    return Scaffold(
      backgroundColor: colors.primaryBg,
      appBar: AppBar(
        backgroundColor: colors.primaryBg,
        title: Text(
          LocaleKeys.settings.tr(),
          style: sectionHeaderStyle,
        ),
      ),
      body: BlocListener<SettingsBloc, SettingsState>(
        listenWhen: _shouldListenToFailure,
        listener: _onFailure,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                LocaleKeys.language.tr(),
                style: sectionHeaderStyle,
              ),
              const SizedBox(height: 8),
              const LanguagePicker(),
            ],
          ),
        ),
      ),
    );
  }

  bool _shouldListenToFailure(SettingsState previous, SettingsState current) {
    return previous.status != current.status &&
           current.status == SettingsStatus.failure;
  }

  void _onFailure(BuildContext context, SettingsState state) {
    ErrorDialog.show(
      context,
      message: state.error ?? LocaleKeys.something_went_wrong.tr(),
    );
  }
}
