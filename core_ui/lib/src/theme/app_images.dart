import '../constants/package_constants.dart';

/// Asset image paths and package constants for core_ui.
class AppImages {
  /// Package name for core_ui resources.
  static const String packageName = PackageConstants.kPackageName;

  static const String _basePath = PackageConstants.kImagesPath;
  static const String _iconsPath = PackageConstants.kIconsPath;

  /// Path to app logo image.
  static const String logo = '$_iconsPath/logo.svg';

  /// Path to app logo text image.
  static const String logoText = '$_iconsPath/logo_text.svg';

  /// Path to app icon image placeholder.
  static const String appIcon = '$_basePath/app_icon.png';

  /// Onboarding slide images (WebP format).
  static const String slide01 = '$_basePath/slide_01.webp';
  static const String slide02 = '$_basePath/slide_02.webp';
  static const String slide03 = '$_basePath/slide_03.webp';
  static const String slide04 = '$_basePath/slide_04.webp';
  static const String slide05 = '$_basePath/slide_05.webp';
  static const String slide06 = '$_basePath/slide_06.webp';
  static const String slide07 = '$_basePath/slide_07.webp';
  static const String slide08 = '$_basePath/slide_08.webp';
  static const String slide09 = '$_basePath/slide_09.webp';
  static const String slide10 = '$_basePath/slide_10.webp';

  /// Path to PNG logo.
  static const String logoPng = '$_basePath/logo.png';

  /// Path to eraser icon.
  static const String eraser = '$_iconsPath/eraser.svg';
}
