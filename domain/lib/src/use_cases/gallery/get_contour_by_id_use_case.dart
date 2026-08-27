import '../../../domain.dart';
import '../use_case.dart';

/// Loads a cached contour by its identifier.
class GetContourByIdUseCase implements FutureUseCase<String, ContourEntity?> {
  final GalleryRepository _repository;

  /// Creates a use case with the given [_repository].
  const GetContourByIdUseCase({required this._repository});

  @override
  Future<ContourEntity?> execute([String? params]) {
    if (params == null) {
      throw ArgumentError('contourId must not be null');
    }
    return _repository.getContourById(params);
  }
}
