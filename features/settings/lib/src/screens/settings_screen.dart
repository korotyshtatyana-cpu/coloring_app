import 'package:auto_route/auto_route.dart';
import 'package:core/core.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:settings/src/screens/settings_content.dart';

import '../bloc/settings_bloc.dart';

/// Settings screen for application preferences.
@RoutePage()
class SettingsScreen extends StatelessWidget {
  /// Creates a [SettingsScreen].
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentLocale = context.locale.toString();

    return BlocProvider<SettingsBloc>(
      create: (context) => SettingsBloc(
        getSettingsUseCase: appLocator<GetSettingsUseCase>(),
        updateSettingsUseCase: appLocator<UpdateSettingsUseCase>(),
      )..add(LoadSettings(currentLocale: currentLocale)),
      child: const SettingsContent(),
    );
  }
}
