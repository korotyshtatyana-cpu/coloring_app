import '../../../domain.dart';
import '../use_case.dart';

/// Saves an exported image file to the device gallery.
class SaveImageToGalleryUseCase implements FutureUseCase<String, void> {
  final CanvasRepository _repository;

  /// Creates a use case with the given [repository].
  const SaveImageToGalleryUseCase({required CanvasRepository repository})
      : _repository = repository;

  @override
  Future<void> execute([String? params]) {
    if (params == null) {
      throw ArgumentError('filePath must not be null');
    }
    return _repository.saveImageToGallery(params);
  }
}
