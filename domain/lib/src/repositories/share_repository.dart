/// Repository for platform sharing operations.
abstract class ShareRepository {
  /// Shares the file at [filePath] using the platform share sheet.
  Future<void> shareFile(String filePath);
}
