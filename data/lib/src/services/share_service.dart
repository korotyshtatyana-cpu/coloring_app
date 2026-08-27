import 'package:share_plus/share_plus.dart';

/// Static service for sharing files via the platform share sheet.
abstract final class ShareService {
  /// Shares the file at [filePath] using the platform share sheet.
  static Future<void> shareFile(String filePath) async {
    await Share.shareXFiles(<XFile>[XFile(filePath)]);
  }
}
