import 'dart:ui';

abstract final class AppLocalization {
  static const String langFolderPath = 'packages/core/resources/lang';

  static const List<Locale> supportedLocales = <Locale>[
    enLocale,
    ruLocale,
    esLocale,
    ptLocale,
    beLocale,
    deLocale,
    frLocale,
  ];

  static Locale get fallbackLocale => enLocale;

  static const Locale enLocale = Locale('en', 'US');
  static const Locale ruLocale = Locale('ru', 'RU');
  static const Locale esLocale = Locale('es', 'ES');
  static const Locale ptLocale = Locale('pt', 'BR');
  static const Locale beLocale = Locale('be', 'BY');
  static const Locale deLocale = Locale('de', 'DE');
  static const Locale frLocale = Locale('fr', 'FR');
}
