import '../../../domain.dart';
import '../use_case.dart';

/// Shares a file at a given path using the platform share sheet.
class ShareFileUseCase implements FutureUseCase<String, void> {
  final ShareRepository _repository;

  /// Creates a use case with the given [repository].
  const ShareFileUseCase({required ShareRepository repository})
      : _repository = repository;

  @override
  Future<void> execute([String? params]) {
    if (params == null) {
      throw ArgumentError('filePath must not be null');
    }
    return _repository.shareFile(params);
  }
}
