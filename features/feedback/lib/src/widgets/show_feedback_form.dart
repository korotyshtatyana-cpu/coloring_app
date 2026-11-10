import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import 'feedback_form.dart';

/// Opens the feedback form in a modal bottom sheet.
Future<void> showFeedbackForm(
  BuildContext context, {
  required FeedbackType type,
  String initialEmail = '',
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      decoration: BoxDecoration(
        color: AppColors.of(context).primaryBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: FeedbackForm(type: type, initialEmail: initialEmail),
    ),
  );
}
