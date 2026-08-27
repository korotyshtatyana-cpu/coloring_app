import 'package:flutter/material.dart';

abstract class AppColors {
  factory AppColors.of(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    return brightness == Brightness.light
        ? const LightColors()
        : const DarkColors();
  }

  Color get primaryBg;

  Color get secondaryBg;

  Color get primaryText;

  Color get secondaryText;

  Color get error;

  Color get green;

  Color get brightAppleGreen;

  Color get yellow;

  Color get fluorescentYellow;

  Color get transparent;

  Color get white;

  Color get black;

  Color get deepCarminePink;

  Color get royalOrange;

  Color get gainsboro;

  Color get vividOrange;

  Color get persianRose;

  Color get averagePurple;

  Color get neonTeal;

  Color get darkBlueGray;

  Color get metallicBlue;

  Color get deepKoamaru;
}

class DarkColors extends LightColors {
  const DarkColors();
}

class LightColors implements AppColors {
  const LightColors();

  @override
  Color get primaryBg => const Color(0xFF007BFE);

  @override
  Color get secondaryBg => const Color(0xFFFFFFFF);

  @override
  Color get primaryText => const Color(0xFFFFFFFF);

  @override
  Color get secondaryText => const Color(0xFF007BFE);

  @override
  Color get transparent => const Color(0x00000000);

  @override
  Color get error => const Color(0xFFFF0000);

  @override
  Color get green => const Color(0xFF14FF00);

  @override
  Color get brightAppleGreen => const Color(0xFF44CB01);

  @override
  Color get yellow => const Color(0xFFFFD700);

  @override
  Color get fluorescentYellow => const Color(0xFFFFF500);

  @override
  Color get white => const Color.fromRGBO(255, 255, 255, 1);

  @override
  Color get black => const Color.fromRGBO(0, 0, 0, 1);

  @override
  Color get deepCarminePink => const Color(0xFFFF3131);

  @override
  Color get royalOrange => const Color(0xFFFF914D);

  @override
  Color get gainsboro => const Color(0xFF3333CC);

  @override
  Color get vividOrange => const Color(0xFFFE5C00);

  @override
  Color get persianRose => const Color(0xFFFA299A);

  @override
  Color get averagePurple => const Color(0xFF7B35CA);

  @override
  Color get neonTeal => const Color(0xFF05D6BA);

  @override
  Color get darkBlueGray => const Color.fromRGBO(96, 106, 137, 1);

  @override
  Color get metallicBlue => const Color.fromRGBO(60, 84, 132, 1);

  @override
  Color get deepKoamaru => const Color.fromRGBO(46, 64, 101, 1);
}
