import '../entities/feedback_entity.dart';

/// Repository for handling user feedback.
abstract class FeedbackRepository {
  /// Submits user feedback to the remote storage.
  Future<void> submitFeedback(FeedbackEntity feedback);
}
