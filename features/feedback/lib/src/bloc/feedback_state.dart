part of 'feedback_bloc.dart';

enum FeedbackStatus { initial, loading, success, failure }

class FeedbackState extends Equatable {
  final FeedbackStatus status;
  final String message;
  final String email;
  final List<String> attachmentPaths;
  final FeedbackType type;
  final String? error;

  const FeedbackState({
    this.status = FeedbackStatus.initial,
    this.message = '',
    this.email = '',
    this.attachmentPaths = const [],
    required this.type,
    this.error,
  });

  @override
  List<Object?> get props => [status, message, email, attachmentPaths, type, error];

  FeedbackState copyWith({
    FeedbackStatus? status,
    String? message,
    String? email,
    List<String>? attachmentPaths,
    FeedbackType? type,
    String? error,
  }) {
    return FeedbackState(
      status: status ?? this.status,
      message: message ?? this.message,
      email: email ?? this.email,
      attachmentPaths: attachmentPaths ?? this.attachmentPaths,
      type: type ?? this.type,
      error: error ?? this.error,
    );
  }
}
