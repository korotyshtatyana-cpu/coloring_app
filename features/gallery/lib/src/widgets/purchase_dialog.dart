import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:subscription/subscription.dart';

import '../bloc/gallery_bloc.dart';
import 'grid/contour_preview.dart';

/// Dialog offering to unlock a paid project individually or via Premium.
class PurchaseDialog extends StatefulWidget {
  /// Paid project the dialog belongs to.
  final ContourEntity contour;

  /// Called after the project was purchased and access was granted.
  final VoidCallback onPurchased;

  /// Creates a [PurchaseDialog].
  const PurchaseDialog({
    required this.contour,
    required this.onPurchased,
    super.key,
  });

  /// Shows the purchase dialog for [contour].
  static Future<void> show(
    BuildContext context, {
    required ContourEntity contour,
  }) {
    final GalleryBloc galleryBloc = context.read<GalleryBloc>();
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) => PurchaseDialog(
        contour: contour,
        onPurchased: () =>
            galleryBloc.add(const LoadMonetizationStatus()),
      ),
    );
  }

  @override
  State<PurchaseDialog> createState() => _PurchaseDialogState();
}

class _PurchaseDialogState extends State<PurchaseDialog> {
  StreamSubscription<PurchaseUpdateEntity>? _updatesSubscription;
  bool _isPurchasing = false;

  @override
  void dispose() {
    _updatesSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return AlertDialog(
      backgroundColor: colors.secondaryBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.all(20),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 1,
                child: ContourPreview(
                  previewUrl: widget.contour.previewUrl,
                  svgUrl: widget.contour.svgUrl,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.contour.title,
              textAlign: TextAlign.center,
              style: AppFonts.semiBold20.copyWith(color: colors.primaryText),
            ),
            if (widget.contour.price != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                LocaleKeys.purchase_dialog_project_price.tr(
                  args: <String>[_formatPrice(widget.contour.price!)],
                ),
                textAlign: TextAlign.center,
                style: AppFonts.normal14.copyWith(color: colors.secondaryText),
              ),
            ],
            const SizedBox(height: 20),
            PrimaryButton(
              text: LocaleKeys.purchase_dialog_buy_project.tr(),
              isLoading: _isPurchasing,
              onPressed: _onBuy,
            ),
            const SizedBox(height: 16),
            Divider(height: 1, thickness: 1, color: colors.accentLight),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    LocaleKeys.subscription_premium_description.tr(),
                    style: AppFonts.normal12.copyWith(
                      color: colors.secondaryText,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.premiumGold,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    LocaleKeys.purchase_dialog_subscribe_badge.tr(),
                    style: AppFonts.normal12.copyWith(
                      color: colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppButton(
              text: LocaleKeys.purchase_dialog_subscribe.tr(),
              filled: true,
              color: colors.premiumGold,
              onPressed: _isPurchasing ? null : _onSubscribe,
            ),
            const SizedBox(height: 8),
            AppButton(
              text: LocaleKeys.purchase_dialog_cancel.tr(),
              onPressed: _isPurchasing ? null : () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onBuy() async {
    if (_isPurchasing) {
      return;
    }
    setState(() => _isPurchasing = true);

    _updatesSubscription = appLocator<WatchPurchaseUpdatesUseCase>()
        .execute()
        .listen(_onUpdate);

    try {
      await appLocator<BuyProjectUseCase>().execute(
        BuyProjectParams(
          contourId: widget.contour.id,
          productId: widget.contour.productId,
        ),
      );
    } catch (e, stackTrace) {
      ErrorHandler.report(e, stackTrace);
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
    }
  }

  void _onUpdate(PurchaseUpdateEntity update) {
    if (!_isRelevant(update)) {
      return;
    }
    _updatesSubscription?.cancel();
    if (!mounted) {
      return;
    }

    switch (update.status) {
      case PurchaseUpdateStatus.success:
        final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
        widget.onPurchased();
        Navigator.of(context).pop();
        messenger.showSnackBar(
          SnackBar(content: Text(LocaleKeys.purchase_success_text.tr())),
        );
      case PurchaseUpdateStatus.pending:
        setState(() => _isPurchasing = false);
        ErrorDialog.show(
          context,
          title: LocaleKeys.purchase_processing_title.tr(),
          message: LocaleKeys.purchase_processing_text.tr(),
        );
      case PurchaseUpdateStatus.failed:
        setState(() => _isPurchasing = false);
        ErrorDialog.show(
          context,
          title: LocaleKeys.purchase_failed_title.tr(),
          message: LocaleKeys.purchase_failed_text.tr(),
        );
      case PurchaseUpdateStatus.canceled:
      case PurchaseUpdateStatus.empty:
        setState(() => _isPurchasing = false);
    }
  }

  bool _isRelevant(PurchaseUpdateEntity update) {
    if (update.isRestore) {
      return false;
    }
    if (update.contourId != null) {
      return update.contourId == widget.contour.id;
    }
    return widget.contour.productId != null &&
        update.productId == widget.contour.productId;
  }

  void _onSubscribe() {
    final router = context.router;
    Navigator.of(context).pop();
    router.push(const SubscriptionRoute());
  }

  String _formatPrice(int cents) {
    final double rubles = cents / 100;
    final String amount = cents % 100 == 0
        ? rubles.toStringAsFixed(0)
        : rubles.toStringAsFixed(2);
    return '$amount ₽';
  }
}
