part of 'feedback_bloc.dart';

abstract class FeedbackEvent extends Equatable {
  const FeedbackEvent();

  @override
  List<Object?> get props => [];
}

class ChangeMessage extends FeedbackEvent {
  final String message;
  const ChangeMessage(this.message);
  @override
  List<Object?> get props => [message];
}

class AddAttachments extends FeedbackEvent {
  final List<String> paths;
  const AddAttachments(this.paths);
  @override
  List<Object?> get props => [paths];
}

class RemoveAttachment extends FeedbackEvent {
  final String path;
  const RemoveAttachment(this.path);
  @override
  List<Object?> get props => [path];
}

class SubmitFeedback extends FeedbackEvent {
  const SubmitFeedback();
}
