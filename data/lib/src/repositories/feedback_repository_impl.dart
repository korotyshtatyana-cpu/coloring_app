import 'dart:io';
import 'package:domain/domain.dart';
import '../providers/feedback_remote_provider.dart';

/// Implementation of [FeedbackRepository] using [FeedbackRemoteProvider].
class FeedbackRepositoryImpl implements FeedbackRepository {
  final FeedbackRemoteProvider _remoteProvider;

  /// Creates a [FeedbackRepositoryImpl] with the given [_remoteProvider].
  FeedbackRepositoryImpl({required FeedbackRemoteProvider remoteProvider})
      : _remoteProvider = remoteProvider;

  @override
  Future<void> submitFeedback(FeedbackEntity feedback) {
    return _remoteProvider.submitFeedback(
      message: feedback.message,
      type: feedback.type.name,
      email: feedback.email,
      attachments: feedback.attachmentPaths.map((path) => File(path)).toList(),
    );
  }
}
