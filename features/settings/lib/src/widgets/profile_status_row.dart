import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

/// Read-only row showing a labelled value, e.g. the subscription status.
class ProfileStatusRow extends StatelessWidget {
  /// Row label.
  final String title;

  /// Value displayed on the right.
  final String value;

  /// Creates a [ProfileStatusRow].
  const ProfileStatusRow({required this.title, required this.value, super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: AppFonts.semiBold20.copyWith(color: colors.primaryText),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppFonts.normal16.copyWith(color: colors.secondaryText),
          ),
        ),
      ],
    );
  }
}
