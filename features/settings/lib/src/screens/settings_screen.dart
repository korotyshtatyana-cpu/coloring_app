import 'package:auto_route/auto_route.dart';
import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../bloc/settings_bloc.dart';
import '../widgets/language_picker.dart';

/// Settings screen for application preferences.
@RoutePage()
class SettingsScreen extends StatelessWidget {
  /// Creates a [SettingsScreen].
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SettingsBloc>(
      create: (context) => SettingsBloc(
        getSettingsUseCase: appLocator<GetSettingsUseCase>(),
        updateSettingsUseCase: appLocator<UpdateSettingsUseCase>(),
      )..add(const LoadSettings()),
      child: const SettingsContent(),
    );
  }
}

class SettingsContent extends StatelessWidget {
  /// Creates [SettingsContent].
  const SettingsContent({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.primaryBg,
      appBar: AppBar(
        backgroundColor: colors.primaryBg,
        title: Text(
          LocaleKeys.profile.tr(),
          style: AppFonts.semiBold20.copyWith(color: colors.primaryText),
        ),
      ),
      body: BlocListener<SettingsBloc, SettingsState>(
        listenWhen: (SettingsState previous, SettingsState current) =>
            previous.status != current.status &&
            current.status == SettingsStatus.failure,
        listener: (BuildContext context, SettingsState state) {
          ErrorDialog.show(
            context,
            message: state.error ?? LocaleKeys.something_went_wrong.tr(),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                LocaleKeys.language.tr(),
                style: AppFonts.semiBold20.copyWith(color: colors.primaryText),
              ),
              const SizedBox(height: 8),
              const LanguagePicker(),
            ],
          ),
        ),
      ),
    );
  }
}
