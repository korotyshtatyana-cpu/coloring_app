import 'package:saver_gallery/saver_gallery.dart';

/// Static service for saving images to the device gallery.
abstract final class GallerySaverService {
  /// Saves the image file at [filePath] to the device gallery.
  static Future<void> saveFile(String filePath) async {
    await SaverGallery.saveFile(
      filePath: filePath,
      fileName: _fileNameFromPath(filePath),
      androidRelativePath: 'Pictures/ColoringApp',
      skipIfExists: false,
    );
  }

  static String _fileNameFromPath(String filePath) {
    final int lastSlash = filePath.lastIndexOf('/');
    final int lastBackslash = filePath.lastIndexOf('\\');
    final int start = (lastSlash > lastBackslash ? lastSlash : lastBackslash) + 1;
    return filePath.substring(start);
  }
}
