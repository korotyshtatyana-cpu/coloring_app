import 'package:flutter/material.dart';

import '../constants/package_constants.dart';

class AppFonts {
  static const String _packageName = PackageConstants.kPackageName;
  static const String _playfairDisplayFamily = 'PlayfairDisplay';
  static const String _montserratFamily = 'Montserrat';

  static TextStyle normal13 = const TextStyle(
    fontWeight: FontWeight.w400,
    fontSize: 13,
    fontFamily: _montserratFamily,
    package: _packageName,
  );

  static TextStyle extraBold56 = const TextStyle(
    fontWeight: FontWeight.w400,
    fontSize: 56,
    fontFamily: _montserratFamily,
    package: _packageName,
    shadows: <Shadow>[
      Shadow(offset: Offset(0, 2), blurRadius: 4),
    ],
  );

  static TextStyle extraBold46 = const TextStyle(
    fontWeight: FontWeight.w800,
    fontSize: 46,
    fontFamily: _montserratFamily,
    package: _packageName,
  );

  static TextStyle extraBold36 = const TextStyle(
    fontWeight: FontWeight.w800,
    fontSize: 36,
    fontFamily: _montserratFamily,
    package: _packageName,
  );

  static TextStyle bold36 = const TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 36,
    fontFamily: _montserratFamily,
    package: _packageName,
    shadows: <Shadow>[
      Shadow(offset: Offset(0, 2), blurRadius: 4),
    ],
  );

  static TextStyle bold32 = const TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 32,
    fontFamily: _montserratFamily,
    package: _packageName,
  );

  static TextStyle normal32 = const TextStyle(
    fontWeight: FontWeight.w400,
    fontSize: 32,
    fontFamily: _montserratFamily,
    package: _packageName,
  );

  static TextStyle bold28 = const TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 28,
    fontFamily: _montserratFamily,
    package: _packageName,
  );

  static TextStyle semiBold28 = const TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 28,
    fontFamily: _montserratFamily,
    package: _packageName,
    shadows: <Shadow>[
      Shadow(offset: Offset(0, 2), blurRadius: 4),
    ],
  );

  static TextStyle semiBold24 = const TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 24,
    fontFamily: _montserratFamily,
    package: _packageName,
  );

  static TextStyle semiBold20 = const TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 20,
    fontFamily: _montserratFamily,
    package: _packageName,
  );

  static TextStyle normal20 = const TextStyle(
    fontWeight: FontWeight.w400,
    fontSize: 18,
    fontFamily: _montserratFamily,
    package: _packageName,
  );

  static TextStyle normal18 = const TextStyle(
    fontWeight: FontWeight.w400,
    fontSize: 18,
    fontFamily: _montserratFamily,
    package: _packageName,
  );

  static TextStyle normal16 = const TextStyle(
    fontWeight: FontWeight.w400,
    fontSize: 16,
    fontFamily: _montserratFamily,
    package: _packageName,
  );

  static TextStyle normal14 = const TextStyle(
    fontWeight: FontWeight.w400,
    fontSize: 14,
    fontFamily: _montserratFamily,
    package: _packageName,
  );

  static TextStyle normal12 = const TextStyle(
    fontWeight: FontWeight.w400,
    fontSize: 14,
    fontFamily: _montserratFamily,
    package: _packageName,
  );

  static TextStyle archivoNarroStyle = const TextStyle(
    fontWeight: FontWeight.w400,
    fontSize: 16,
    fontFamily: _montserratFamily,
    package: _packageName,
  );
}
