import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

import '../bloc/settings_bloc.dart';

/// Dropdown for selecting the application language.
class LanguagePicker extends StatelessWidget {
  /// Creates a [LanguagePicker].
  const LanguagePicker({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final String locale = context.select(
      (SettingsBloc bloc) => bloc.state.locale,
    );

    return DropdownButton<String>(
      value: locale,
      dropdownColor: colors.secondaryBg,
      style: AppFonts.normal16.copyWith(color: colors.primaryText),
      items: const <DropdownMenuItem<String>>[
        DropdownMenuItem<String>(
          value: 'en',
          child: Text('English'),
        ),
        DropdownMenuItem<String>(
          value: 'ru',
          child: Text('Русский'),
        ),
      ],
      onChanged: (String? value) {
        if (value != null) {
          context.read<SettingsBloc>().add(ChangeLanguage(value));
          context.setLocale(Locale(value));
        }
      },
    );
  }
}
