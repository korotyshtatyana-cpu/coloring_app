import 'dart:ui';

abstract final class AppLocalization {
  static const String langFolderPath = 'packages/core/resources/lang';

  static const List<Locale> supportedLocales = <Locale>[
    enLocale,
    ruLocale,
  ];

  static Locale get fallbackLocale => enLocale;

  static const Locale enLocale = Locale('en', 'US');
  static const Locale ruLocale = Locale('ru', 'RU');
}
