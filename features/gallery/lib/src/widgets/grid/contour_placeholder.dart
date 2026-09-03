import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

class ContourPlaceholder extends StatelessWidget {
  const ContourPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return Container(
      color: colors.secondaryBg,
      padding: const EdgeInsets.all(12),
      child: Icon(
        Icons.image,
        color: colors.primaryBg,
        size: 48,
      ),
    );
  }
}