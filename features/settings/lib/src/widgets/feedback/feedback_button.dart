import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

class FeedbackButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const FeedbackButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ListTile(
      leading: Icon(icon, color: colors.iconPrimary),
      title: Text(label, style: AppFonts.normal16),
      trailing: Icon(Icons.chevron_right_rounded, color: colors.iconDisabled),
      onTap: onPressed,
      contentPadding: EdgeInsets.zero,
    );
  }
}
