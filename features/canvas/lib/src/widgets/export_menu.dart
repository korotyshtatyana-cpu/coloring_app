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

    return IntrinsicWidth(
      child: Material(
        color: colors.primaryBg,
        elevation: 4,
        shadowColor: colors.accentDark.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  LocaleKeys.export.tr(),
                  style: AppFonts.semiBold20.copyWith(color: colors.primaryText),
                ),
              ),
              const SizedBox(height: 4),
              ListTile(
                leading: Icon(Icons.share, color: colors.primaryText),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                title: Text(
                  LocaleKeys.share.tr(),
                  style: AppFonts.normal16.copyWith(color: colors.primaryText),
                ),
                onTap: onShare,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                dense: true,
                visualDensity: VisualDensity.compact,
                minLeadingWidth: 24,
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: colors.primaryText),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                title: Text(
                  LocaleKeys.save_to_gallery.tr(),
                  style: AppFonts.normal16.copyWith(color: colors.primaryText),
                ),
                onTap: onSaveToGallery,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                dense: true,
                visualDensity: VisualDensity.compact,
                minLeadingWidth: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}