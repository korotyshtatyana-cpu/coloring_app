import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

/// Utility class for URL operations.
abstract final class UrlUtils {
  /// Opens the store listing for the application.
  static Future<void> openStoreListing() async {
    final String url = Platform.isIOS
        ? 'https://apps.apple.com/app/id6470123456' // Replace with real iOS ID
        : 'https://play.google.com/store/apps/details?id=com.coloringpro.app'; // Replace with real Android ID
    
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Launches a generic [url].
  static Future<void> launch(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
