import 'dart:async';
import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../../subscription.dart';
import 'preview/contour_preview.dart';

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
    VoidCallback? onPurchased,
  }) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => PurchaseDialog(
        contour: contour,
        onPurchased: () => onPurchased?.call(),
      ),
    );
  }

  @override
  State<PurchaseDialog> createState() => _PurchaseDialogState();
}

class _PurchaseDialogState extends State<PurchaseDialog> {
  StreamSubscription<PurchaseUpdateEntity>? _updatesSubscription;
  BillingProductEntity? _creditProduct;
  bool _isLoadingProduct = true;
  bool _productLoadFailed = false;
  bool _isPurchasing = false;
  bool _isCheckingPending = true;
  bool _isPending = false;
  bool _isRefreshingPending = false;
  bool _showPendingRetryMessage = false;
  PendingPurchaseEntity? _pendingPurchase;

  @override
  void initState() {
    super.initState();
    _loadCreditProduct();
    _checkPendingPurchase();
  }

  @override
  void dispose() {
    _updatesSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final bool isLandscape = mediaQuery.orientation == Orientation.landscape;

    final double dialogWidth = math.min(
      isLandscape ? 720 : 400,
      mediaQuery.size.width - 48,
    );
    final double contentWidth = dialogWidth - 40;
    final double imageSize;
    if (isLandscape) {
      final double purchaseCardWidth = (contentWidth - 16) * 3 / 5;
      final double purchaseCardInnerWidth = purchaseCardWidth - 32;
      imageSize = math.max(0.0, math.min(160, purchaseCardInnerWidth * 0.55));
    } else {
      imageSize = math.max(0.0, math.min(220.0, contentWidth - 32));
    }

    return AlertDialog(
      backgroundColor: colors.secondaryBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      constraints: BoxConstraints(maxWidth: isLandscape ? 720 : 400),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      titlePadding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
      title: Align(
        alignment: Alignment.topRight,
        child: IconButton(
          onPressed: _isPurchasing ? null : () => Navigator.of(context).pop(),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          color: colors.primaryText,
          icon: const Icon(Icons.close),
        ),
      ),
      contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      content: _buildDetails(
        colors,
        isLandscape: isLandscape,
        imageSize: imageSize,
      ),
    );
  }

  Widget _buildImage({double size = 220}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: size,
        height: size,
        child: ContourPreview(
          previewUrl: widget.contour.previewUrl,
          svgUrl: widget.contour.svgUrl,
        ),
      ),
    );
  }

  Widget _buildDetails(
    AppColors colors, {
    required bool isLandscape,
    required double imageSize,
  }) {
    if (isLandscape) {
      return Row(
        children: <Widget>[
          Expanded(
            flex: 2,
            child: _buildPurchaseBlock(
              colors,
              isLandscape: true,
              imageSize: imageSize,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: _buildSubscriptionBlock(colors)),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildPurchaseBlock(colors, isLandscape: false, imageSize: imageSize),
        const SizedBox(height: 16),
        _buildSubscriptionBlock(colors),
      ],
    );
  }

  Widget _buildPurchaseBlock(
    AppColors colors, {
    required bool isLandscape,
    required double imageSize,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colors.accentLight, width: 2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(child: _buildImage(size: imageSize)),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    top: 8.0,
                    right: 16.0,
                  ),
                  child: Text(
                    LocaleKeys.subscription_premium_description.tr(),
                    style: AppFonts.normal12.copyWith(
                      color: colors.secondaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    if (_isCheckingPending) ...[
                      const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ] else if (_isPending) ...[
                      if (_showPendingRetryMessage) ...[
                        const SizedBox(height: 8),
                        Text(
                          LocaleKeys.purchase_pending_retry_text.tr(),
                          style: AppFonts.normal12.copyWith(
                            color: colors.secondaryText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        Text(
                          LocaleKeys.purchase_processing_text.tr(),
                          style: AppFonts.normal12.copyWith(
                            color: colors.secondaryText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 12),
                      AppButton(
                        text: _isRefreshingPending
                            ? LocaleKeys.purchase_checking_text.tr()
                            : LocaleKeys.purchase_processing_title.tr(),
                        onPressed: _isRefreshingPending
                            ? null
                            : _onRefreshPending,
                        filled: true,
                        color: colors.accentLight,
                      ),
                    ] else if (_isLoadingProduct) ...[
                      const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ] else if (_productLoadFailed) ...[
                      TextButton(
                        onPressed: _loadCreditProduct,
                        child: Text(LocaleKeys.retry.tr()),
                      ),
                    ] else if (_creditProduct != null) ...[
                      AppButton(
                        text: LocaleKeys.purchase_dialog_buy_project.tr(),
                        onPressed: _isPurchasing || _creditProduct == null
                            ? null
                            : _onBuy,
                        filled: true,
                        color: colors.accentLight,
                        isLoading: _isPurchasing,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (_creditProduct != null && !_isPending) ...<Widget>[
            Align(
              alignment: Alignment.topRight,
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 10,
                ),
                decoration: BoxDecoration(
                  color: colors.accentLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _creditProduct!.price,
                  textAlign: TextAlign.center,
                  style: AppFonts.price.copyWith(color: colors.white),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubscriptionBlock(AppColors colors) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colors.premiumGold, width: 2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: colors.premiumGold,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
              ),
              child: Text(
                LocaleKeys.purchase_dialog_subscribe_badge.tr(),
                style: AppFonts.tooltip.copyWith(color: colors.white),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 8.0, right: 16.0),
            child: Text(
              LocaleKeys.subscription_premium_description.tr(),
              style: AppFonts.normal12.copyWith(color: colors.secondaryText),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              bottom: 16.0,
              right: 16.0,
            ),
            child: AppButton(
              text: LocaleKeys.purchase_dialog_subscribe.tr(),
              filled: true,
              color: colors.premiumGold,
              isLoading: _isPurchasing,
              onPressed: _isPurchasing ? null : _onSubscribe,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadCreditProduct() async {
    if (!_isLoadingProduct) {
      setState(() {
        _isLoadingProduct = true;
        _productLoadFailed = false;
      });
    }
    try {
      final BillingProductEntity? product =
          await appLocator<GetCreditProductUseCase>().execute();
      if (!mounted) {
        return;
      }
      setState(() {
        _creditProduct = product;
        _isLoadingProduct = false;
        _productLoadFailed = product == null;
      });
    } catch (e, stackTrace) {
      ErrorHandler.report(e, stackTrace);
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingProduct = false;
        _productLoadFailed = true;
      });
    }
  }

  Future<void> _checkPendingPurchase() async {
    try {
      final UserEntity? user = await appLocator<GetCurrentUserUseCase>()
          .execute();
      if (user == null) {
        if (mounted) {
          setState(() => _isCheckingPending = false);
        }
        return;
      }

      final UserEntitlementEntity? entitlement =
          await appLocator<GetEntitlementUseCase>().execute(
            GetEntitlementParams(userId: user.id, contourId: widget.contour.id),
          );
      if (entitlement != null) {
        if (!mounted) {
          return;
        }
        final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
        widget.onPurchased();
        Navigator.of(context).pop();
        messenger.showSnackBar(
          SnackBar(content: Text(LocaleKeys.purchase_success_text.tr())),
        );
        return;
      }

      final List<PendingPurchaseEntity> pending =
          await appLocator<GetPendingPurchasesUseCase>().execute(user.id);
      PendingPurchaseEntity? pendingPurchase;
      for (final PendingPurchaseEntity purchase in pending) {
        if (purchase.status == PendingPurchaseStatus.pending &&
            purchase.contourId == widget.contour.id) {
          pendingPurchase = purchase;
          break;
        }
      }
      final bool isPending = pendingPurchase != null;
      if (!mounted) {
        return;
      }
      setState(() {
        _isPending = isPending;
        _pendingPurchase = pendingPurchase;
        _isCheckingPending = false;
      });
      if (isPending && _updatesSubscription == null) {
        _updatesSubscription = appLocator<WatchPurchaseUpdatesUseCase>()
            .execute()
            .listen(_onUpdate);
      }
    } catch (e, stackTrace) {
      ErrorHandler.report(e, stackTrace);
      if (mounted) {
        setState(() => _isCheckingPending = false);
      }
    }
  }

  Future<void> _onRefreshPending() async {
    if (_isRefreshingPending) {
      return;
    }
    setState(() {
      _isRefreshingPending = true;
      _showPendingRetryMessage = false;
    });

    try {
      final PendingPurchaseEntity? purchase = _pendingPurchase;
      if (purchase == null) {
        await _checkPendingPurchase();
        if (mounted) {
          setState(() => _isRefreshingPending = false);
        }
        return;
      }

      final PendingPurchaseRefreshStatus result =
          await appLocator<RefreshPendingPurchaseUseCase>().execute(purchase);
      if (!mounted) {
        return;
      }

      if (result == PendingPurchaseRefreshStatus.verified) {
        final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
        widget.onPurchased();
        Navigator.of(context).pop();
        messenger.showSnackBar(
          SnackBar(content: Text(LocaleKeys.purchase_success_text.tr())),
        );
        return;
      }
      if (result == PendingPurchaseRefreshStatus.failed) {
        _updatesSubscription?.cancel();
        _updatesSubscription = null;
        setState(() {
          _isRefreshingPending = false;
          _isPending = false;
          _pendingPurchase = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocaleKeys.purchase_canceled_text.tr())),
        );
        return;
      }

      setState(() {
        _isRefreshingPending = false;
        _showPendingRetryMessage = true;
      });
    } catch (e, stackTrace) {
      ErrorHandler.report(e, stackTrace);
      if (!mounted) {
        return;
      }
      setState(() => _isRefreshingPending = false);
      ErrorDialog.show(
        context,
        title: LocaleKeys.purchase_failed_title.tr(),
        message: LocaleKeys.purchase_failed_text.tr(),
      );
    }
  }

  Future<void> _onBuy() async {
    if (_isPurchasing || _creditProduct == null) {
      return;
    }
    setState(() => _isPurchasing = true);

    _updatesSubscription = appLocator<WatchPurchaseUpdatesUseCase>()
        .execute()
        .listen(_onUpdate);

    try {
      await appLocator<BuyCreditUseCase>().execute(
        BuyCreditParams(contourId: widget.contour.id),
      );
    } catch (e, stackTrace) {
      ErrorHandler.report(e, stackTrace);
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
    }
  }

  Future<void> _onUpdate(PurchaseUpdateEntity update) async {
    if (!_isRelevant(update)) {
      return;
    }
    if (update.status == PurchaseUpdateStatus.pending) {
      if (!mounted || _isPending) {
        return;
      }
      setState(() {
        _isPurchasing = true;
        _isPending = true;
      });
      await _checkPendingPurchase();
      return;
    }
    _updatesSubscription?.cancel();
    _updatesSubscription = null;
    if (!mounted) {
      return;
    }

    switch (update.status) {
      case PurchaseUpdateStatus.success:
        widget.onPurchased();
        Navigator.of(context).pop();
      case PurchaseUpdateStatus.pending:
        break;
      case PurchaseUpdateStatus.failed:
        setState(() {
          _isPurchasing = false;
          _isPending = false;
        });
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
}
