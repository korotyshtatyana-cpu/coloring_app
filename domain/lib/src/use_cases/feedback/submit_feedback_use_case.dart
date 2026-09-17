import '../../entities/feedback_entity.dart';
import '../../repositories/feedback_repository.dart';
import '../use_case.dart';

/// Use case for submitting user feedback.
class SubmitFeedbackUseCase implements FutureUseCase<FeedbackEntity, void> {
  final FeedbackRepository _repository;

  /// Creates a [SubmitFeedbackUseCase] with the given [_repository].
  const SubmitFeedbackUseCase({required this._repository});

  @override
  Future<void> execute([FeedbackEntity? params]) {
    if (params == null) throw ArgumentError('params cannot be null');
    return _repository.submitFeedback(params);
  }
}
