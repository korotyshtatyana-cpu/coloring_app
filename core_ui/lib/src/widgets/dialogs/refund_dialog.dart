import 'package:core/core.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../buttons/app_button.dart';

/// One entry of the refund dialog: the message and the contour preview
/// shown for a single refunded purchase.
class RefundDialogEntry {
  /// Localized message describing the refund.
  final String message;

  /// Preview image URL of the affected contour, when resolvable.
  final String? previewUrl;

  /// Creates a [RefundDialogEntry].
  const RefundDialogEntry({required this.message, this.previewUrl});
}

/// Modal dialog informing the user that a purchase was refunded and the
/// access it granted is revoked.
///
/// Several refunds arriving within a short window are merged into a single
/// dialog with one row per refund. The dialog cannot be dismissed without
/// pressing the OK button, which acknowledges the refund.
class RefundDialog extends StatelessWidget {
  /// Refunds to display, one row each.
  final List<RefundDialogEntry> entries;

  /// Creates a [RefundDialog].
  const RefundDialog({required this.entries, super.key});

  /// Shows the refund dialog with the given [entries].
  static Future<void> show(
    BuildContext context, {
    required List<RefundDialogEntry> entries,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: RefundDialog(entries: entries),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return AlertDialog(
      backgroundColor: colors.secondaryBg,
      title: Text(
        LocaleKeys.refund_dialog_title.tr(),
        style: AppFonts.semiBold20.copyWith(color: colors.accentDark),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final RefundDialogEntry entry in entries)
            entries.length == 1
                ? _SingleRefund(entry: entry, colors: colors)
                : _RefundRow(entry: entry, colors: colors),
        ],
      ),
      actions: <Widget>[
        AppButton(
          text: LocaleKeys.refund_dialog_ok.tr(),
          filled: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

/// Content for a single refund: a large preview (when available) above the
/// message.
class _SingleRefund extends StatelessWidget {
  final RefundDialogEntry entry;
  final AppColors colors;

  const _SingleRefund({required this.entry, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (entry.previewUrl != null) ...<Widget>[
          _RefundPreview(previewUrl: entry.previewUrl!, size: 120, colors: colors),
          const SizedBox(height: 16),
        ],
        Text(
          entry.message,
          textAlign: TextAlign.center,
          style: AppFonts.normal16.copyWith(color: colors.primaryText),
        ),
      ],
    );
  }
}

/// One row of a merged dialog: a small preview next to the message.
class _RefundRow extends StatelessWidget {
  final RefundDialogEntry entry;
  final AppColors colors;

  const _RefundRow({required this.entry, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          if (entry.previewUrl != null) ...<Widget>[
            _RefundPreview(previewUrl: entry.previewUrl!, size: 56, colors: colors),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              entry.message,
              style: AppFonts.normal16.copyWith(color: colors.primaryText),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded contour preview with a neutral fallback when the image cannot
/// be loaded.
class _RefundPreview extends StatelessWidget {
  final String previewUrl;
  final double size;
  final AppColors colors;

  const _RefundPreview({
    required this.previewUrl,
    required this.size,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        previewUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (BuildContext context, Object error, StackTrace? stack) {
          return Container(
            width: size,
            height: size,
            color: colors.secondaryBg,
            child: Icon(Icons.image, size: size / 2, color: colors.secondaryText),
          );
        },
      ),
    );
  }
}
