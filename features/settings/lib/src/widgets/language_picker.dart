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
    final String locale = context.select(
      (SettingsBloc bloc) => bloc.state.locale,
    );

    return AppDropdown<String>(
      value: locale,
      width: 200,
      items: <DropdownMenuItem<String>>[
        DropdownMenuItem<String>(
          value: 'en-US',
          child: Text(LocaleKeys.english.tr()),
        ),
        DropdownMenuItem<String>(
          value: 'ru-RU',
          child: Text(LocaleKeys.russian.tr()),
        ),
        DropdownMenuItem<String>(
          value: 'es-ES',
          child: Text(LocaleKeys.spanish.tr()),
        ),
        DropdownMenuItem<String>(
          value: 'pt-BR',
          child: Text(LocaleKeys.portuguese.tr()),
        ),
        DropdownMenuItem<String>(
          value: 'be-BY',
          child: Text(LocaleKeys.belarusian.tr()),
        ),
        DropdownMenuItem<String>(
          value: 'de-DE',
          child: Text(LocaleKeys.german.tr()),
        ),
        DropdownMenuItem<String>(
          value: 'fr-FR',
          child: Text(LocaleKeys.french.tr()),
        ),
      ],
      onChanged: (String? value) {
        if (value != null) {
          context.read<SettingsBloc>().add(ChangeLanguage(value));

          final parts = value.split('-');
          context.setLocale(Locale(parts[0], parts[1]));
        }
      },
    );
  }
}
