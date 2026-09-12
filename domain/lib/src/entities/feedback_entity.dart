import 'package:equatable/equatable.dart';

/// Types of user feedback.
enum FeedbackType {
  /// Bug report.
  bug,

  /// Feature suggestion.
  feature,

  /// General inquiry.
  general,
}

/// Domain entity representing a piece of user feedback.
class FeedbackEntity extends Equatable {
  /// The feedback message content.
  final String message;

  /// The category of feedback.
  final FeedbackType type;

  /// The contact email for the feedback.
  final String email;

  /// List of attachment file paths.
  final List<String> attachmentPaths;

  /// Creates a [FeedbackEntity].
  const FeedbackEntity({
    required this.message,
    required this.type,
    required this.email,
    this.attachmentPaths = const [],
  });

  @override
  List<Object?> get props => [message, type, email, attachmentPaths];
}
