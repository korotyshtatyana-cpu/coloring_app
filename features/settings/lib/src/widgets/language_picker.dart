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
      items: <DropdownMenuItem<String>>[
        DropdownMenuItem<String>(
          value: 'en-US',
          child: Text('english'.tr()),
        ),
        DropdownMenuItem<String>(
          value: 'ru-RU',
          child: Text('russian'.tr()),
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
