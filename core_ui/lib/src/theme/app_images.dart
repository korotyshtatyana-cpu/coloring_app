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
  static const String appIcon = 'assets/images/app_icon.png';

  /// Path to PNG logo.
  static const String logoPng = '$_basePath/logo.png';

  /// Path to eraser icon.
  static const String eraser = '$_iconsPath/eraser.svg';
}
