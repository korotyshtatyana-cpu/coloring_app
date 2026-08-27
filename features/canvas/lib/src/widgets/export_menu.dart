import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

/// Export options menu.
class ExportMenu extends StatelessWidget {
  /// Callback when share is selected.
  final VoidCallback onShare;

  /// Callback when save to gallery is selected.
  final VoidCallback onSaveToGallery;

  /// Creates an [ExportMenu].
  const ExportMenu({
    required this.onShare,
    required this.onSaveToGallery,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return Material(
      color: Colors.white,
      elevation: 8,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              LocaleKeys.export.tr(),
              style: AppFonts.semiBold20.copyWith(color: colors.black),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.share, color: colors.black),
              title: Text(
                LocaleKeys.share.tr(),
                style: AppFonts.normal16.copyWith(color: colors.black),
              ),
              onTap: onShare,
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: colors.black),
              title: Text(
                LocaleKeys.save_to_gallery.tr(),
                style: AppFonts.normal16.copyWith(color: colors.black),
              ),
              onTap: onSaveToGallery,
            ),
          ],
        ),
      ),
    );
  }
}
