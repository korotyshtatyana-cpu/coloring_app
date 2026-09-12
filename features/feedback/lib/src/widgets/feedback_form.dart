import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../bloc/feedback_bloc.dart';
import 'attachments.dart';

class FeedbackForm extends StatelessWidget {
  final FeedbackType type;
  final String initialEmail;

  const FeedbackForm({
    required this.type,
    required this.initialEmail,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return BlocProvider(
      create: (context) => FeedbackBloc(
        submitFeedbackUseCase: appLocator<SubmitFeedbackUseCase>(),
        type: type,
        initialEmail: initialEmail,
      ),
      child: BlocConsumer<FeedbackBloc, FeedbackState>(
        listener: (context, state) {
          if (state.status == FeedbackStatus.success) {
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            Navigator.of(context).pop();
            scaffoldMessenger.showSnackBar(
              SnackBar(content: Text(LocaleKeys.feedback_sent.tr())),
            );
          }
        },
        builder: (context, state) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  type == FeedbackType.bug
                      ? LocaleKeys.report_a_problem.tr()
                      : LocaleKeys.suggest_an_idea.tr(),
                  style: AppFonts.semiBold20,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextField(
                  maxLines: 5,
                  maxLength: 5000,
                  decoration: InputDecoration(
                    labelText: LocaleKeys.message.tr(),
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: colors.white,
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: colors.accentLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: colors.accentLight),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: colors.accentLight),
                    ),
                  ),
                  onChanged: (val) {
                    context.read<FeedbackBloc>().add(ChangeMessage(val));
                  },
                ),
                const SizedBox(height: 16),
                Attachments(attachmentPaths: state.attachmentPaths),
                const SizedBox(height: 24),
                AppButton(
                  text: state.status == FeedbackStatus.loading
                      ? LocaleKeys.loading.tr()
                      : LocaleKeys.submit.tr(),
                  filled: true,
                  onPressed:
                      state.message.isNotEmpty &&
                          state.status != FeedbackStatus.loading
                      ? () {
                          context.read<FeedbackBloc>().add(
                            const SubmitFeedback(),
                          );
                        }
                      : null,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
