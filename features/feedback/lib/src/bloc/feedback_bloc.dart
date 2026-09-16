import 'dart:async';
import 'package:core/core.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';

part 'feedback_event.dart';
part 'feedback_state.dart';

class FeedbackBloc extends Bloc<FeedbackEvent, FeedbackState> {
  final SubmitFeedbackUseCase _submitFeedbackUseCase;

  FeedbackBloc({
    required SubmitFeedbackUseCase submitFeedbackUseCase,
    required FeedbackType type,
    required String initialEmail,
  }) : _submitFeedbackUseCase = submitFeedbackUseCase,
       super(FeedbackState(type: type, email: initialEmail)) {
    on<ChangeMessage>(_onChangeMessage);
    on<AddAttachments>(_onAddAttachments);
    on<RemoveAttachment>(_onRemoveAttachment);
    on<SubmitFeedback>(_onSubmitFeedback);
  }

  void _onChangeMessage(ChangeMessage event, Emitter<FeedbackState> emit) {
    emit(state.copyWith(message: event.message));
  }

  void _onAddAttachments(AddAttachments event, Emitter<FeedbackState> emit) {
    final List<String> updated = [...state.attachmentPaths, ...event.paths];
    if (updated.length > 3) {
      updated.removeRange(3, updated.length);
    }
    emit(state.copyWith(attachmentPaths: updated));
  }

  void _onRemoveAttachment(RemoveAttachment event, Emitter<FeedbackState> emit) {
    final List<String> updated = [...state.attachmentPaths]..remove(event.path);
    emit(state.copyWith(attachmentPaths: updated));
  }

  Future<void> _onSubmitFeedback(
    SubmitFeedback event,
    Emitter<FeedbackState> emit,
  ) async {
    if (state.message.isEmpty) return;

    try {
      emit(state.copyWith(status: FeedbackStatus.loading));
      
      await _submitFeedbackUseCase.execute(FeedbackEntity(
        message: state.message,
        type: state.type,
        email: state.email,
        attachmentPaths: state.attachmentPaths,
      ));

      emit(state.copyWith(status: FeedbackStatus.success));
    } catch (e, stackTrace) {
      ErrorHandler.report(e, stackTrace);
      emit(state.copyWith(
        status: FeedbackStatus.failure,
        error: e.toString(),
      ));
    }
  }
}
