import 'package:image_gallery_saver/image_gallery_saver.dart';

/// Static service for saving images to the device gallery.
abstract final class GallerySaverService {
  /// Saves the image file at [filePath] to the device gallery.
  static Future<void> saveFile(String filePath) async {
    await ImageGallerySaver.saveFile(filePath);
  }
}
