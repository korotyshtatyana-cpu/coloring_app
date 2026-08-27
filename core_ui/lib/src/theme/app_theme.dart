import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_dimens.dart';
import 'app_fonts.dart';

const LightColors _appColors = LightColors();

final ThemeData lightTheme = ThemeData.light().copyWith(
  scaffoldBackgroundColor: _appColors.primaryBg,
  textTheme: _getTextTheme(),
  inputDecorationTheme: _getInputDecorationTheme(),
  primaryColor: _appColors.primaryBg,
  colorScheme: ColorScheme.fromSwatch().copyWith(
    secondary: _appColors.secondaryBg,
    primary: _appColors.primaryBg,
    error: _appColors.error,
  ),
  textSelectionTheme: TextSelectionThemeData(
    cursorColor: _appColors.white,
    selectionColor: Colors.white.withValues(alpha: 0.3),
    selectionHandleColor: _appColors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      backgroundColor: _appColors.secondaryBg,
      foregroundColor: _appColors.primaryBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(
        vertical: 8,
        horizontal: 16,
      ),
      textStyle: AppFonts.semiBold24,
    ),
  ),
  progressIndicatorTheme: ProgressIndicatorThemeData(
    color: _appColors.secondaryBg,
  ),
  checkboxTheme: CheckboxThemeData(
    side: BorderSide(
      color: _appColors.white,
      width: 2.0,
    ),
    checkColor: WidgetStateProperty.all(_appColors.primaryBg),
    fillColor:
        WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        return _appColors.white;
      }
      return null;
    }),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4.0),
    ),
  ),
);

TextTheme _getTextTheme() {
  return TextTheme(
    displayLarge: AppFonts.extraBold56,
    displayMedium: AppFonts.extraBold46,
    displaySmall: AppFonts.extraBold36,
    headlineLarge: AppFonts.bold36,
    headlineMedium: AppFonts.bold32,
    headlineSmall: AppFonts.bold28,
    titleLarge: AppFonts.semiBold28,
    titleMedium: AppFonts.semiBold24,
    titleSmall: AppFonts.semiBold20,
    bodyLarge: AppFonts.normal20,
    bodyMedium: AppFonts.normal18,
    bodySmall: AppFonts.normal16,
    labelLarge: AppFonts.normal16,
    labelMedium: AppFonts.normal14,
    labelSmall: AppFonts.normal12,
  ).apply(
    displayColor: _appColors.primaryText,
    bodyColor: _appColors.primaryText,
  );
}

InputDecorationTheme _getInputDecorationTheme() {
  return InputDecorationTheme(
    hintStyle: AppFonts.normal18.copyWith(color: _appColors.primaryText),
    border: OutlineInputBorder(
      borderRadius: const BorderRadius.all(
        Radius.circular(AppDimens.defaultBorder),
      ),
      borderSide: BorderSide(
        color: _appColors.primaryBg,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: const BorderRadius.all(
        Radius.circular(AppDimens.defaultBorder),
      ),
      borderSide: BorderSide(
        color: _appColors.primaryBg,
        width: 2,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: const BorderRadius.all(
        Radius.circular(AppDimens.smallBorder),
      ),
      borderSide: BorderSide(
        color: _appColors.secondaryBg,
        width: 2,
      ),
    ),
    labelStyle: AppFonts.normal13.copyWith(color: _appColors.primaryBg),
  );
}
