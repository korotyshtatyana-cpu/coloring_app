import 'package:core/core.dart';
import 'package:domain/domain.dart';

/// Localization helpers for [ContourCategory].
extension ContourCategoryLocalization on ContourCategory {
  /// Returns the localization key for this category.
  String get _localizationKey {
    return switch (this) {
      ContourCategory.all => LocaleKeys.all,
      ContourCategory.animals => LocaleKeys.animals,
      ContourCategory.nature => LocaleKeys.nature,
      ContourCategory.fantasy => LocaleKeys.fantasy,
      ContourCategory.mandala => LocaleKeys.mandala,
      ContourCategory.transport => LocaleKeys.transport,
      ContourCategory.cities => LocaleKeys.cities,
      ContourCategory.people => LocaleKeys.people,
      ContourCategory.flowers => LocaleKeys.flowers,
      ContourCategory.patterns => LocaleKeys.patterns,
      ContourCategory.abstract => LocaleKeys.abstract,
    };
  }

  /// Returns the localized name of this category.
  String localized() => _localizationKey.tr();
}
