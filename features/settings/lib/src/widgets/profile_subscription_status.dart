import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

/// Read-only row showing a labelled value, e.g. the subscription status.
class ProfileSubscriptionStatus extends StatelessWidget {
  /// Row label.
  final String title;

  /// Value displayed on the right.
  final String value;

  /// Creates a [ProfileSubscriptionStatus].
  const ProfileSubscriptionStatus({required this.title, required this.value, super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return Align(
      alignment: Alignment.topRight,
      child: Text(
        value,
        textAlign: TextAlign.right,
        style: AppFonts.normal12.copyWith(color: colors.secondaryText),
      ),
    );
  }
}
