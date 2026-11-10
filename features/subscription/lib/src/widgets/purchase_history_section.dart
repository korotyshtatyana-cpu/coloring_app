import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../utils/subscription_formatters.dart';

/// Section listing the user's resolved purchases.
///
/// The list is capped at [maxHeight] so a long history cannot push the rest of
/// the screen far down. When the content is taller than the cap, the list
/// scrolls inside that area; otherwise it shrinks to fit its rows.
class PurchaseHistorySection extends StatefulWidget {
  /// Maximum height of the scrollable history area.
  static const double maxHeight = 200;

  /// Resolved purchases, most recent first.
  final List<PendingPurchaseEntity> history;

  /// Creates a [PurchaseHistorySection].
  const PurchaseHistorySection({required this.history, super.key});

  @override
  State<PurchaseHistorySection> createState() => _PurchaseHistorySectionState();
}

class _PurchaseHistorySectionState extends State<PurchaseHistorySection> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          LocaleKeys.subscription_history_title.tr(),
          style: AppFonts.semiBold20.copyWith(color: colors.primaryText),
        ),
        const SizedBox(height: 12),
        if (widget.history.isEmpty)
          Text(
            LocaleKeys.subscription_history_empty.tr(),
            style: AppFonts.normal14.copyWith(color: colors.secondaryText),
          )
        else
          Scrollbar(
            controller: _scrollController,
            // A visible thumb makes the extra rows discoverable when the
            // section is nested inside the page scroll view.
            thumbVisibility: true,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: PurchaseHistorySection.maxHeight,
              ),
              child: ListView.separated(
                controller: _scrollController,
                // The section lives inside the page ListView, so this list
                // must own its scrolling instead of using the primary one.
                primary: false,
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                // Keep the scrollbar from covering the row content.
                padding: const EdgeInsets.only(right: 8),
                itemCount: widget.history.length,
                separatorBuilder: (BuildContext context, int index) =>
                    const SizedBox(height: 8),
                itemBuilder: (BuildContext context, int index) =>
                    _HistoryRow(purchase: widget.history[index]),
              ),
            ),
          ),
      ],
    );
  }
}

/// One row of the purchase history.
class _HistoryRow extends StatelessWidget {
  /// Purchase shown by this row.
  final PendingPurchaseEntity purchase;

  const _HistoryRow({required this.purchase});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.secondaryBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          if (purchase.contourPreviewUrl != null &&
              purchase.contourPreviewUrl!.isNotEmpty) ...<Widget>[
            _HistoryThumbnail(
              url: purchase.contourPreviewUrl!,
              fallbackColor: colors.primaryBg,
              iconColor: colors.iconDisabled,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _title(purchase),
                  style: AppFonts.normal14.copyWith(color: colors.primaryText),
                ),
                if (_hasDetails(purchase))
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: _HistoryDetails(
                      purchase: purchase,
                      detailsColor: colors.secondaryText,
                      badgeColor: colors.accentLight,
                      badgeTextColor: colors.accentDark,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            SubscriptionFormatters.date(
              purchase.resolvedAt ?? purchase.createdAt,
            ),
            style: AppFonts.normal12.copyWith(color: colors.secondaryText),
          ),
        ],
      ),
    );
  }

  /// Human-readable name of the purchased item.
  ///
  /// Project purchases use the contour title, subscriptions use the localized
  /// plan name, and anything else falls back to the raw product identifier.
  static String _title(PendingPurchaseEntity purchase) {
    final String? contourTitle = purchase.contourTitle;
    if (contourTitle != null && contourTitle.isNotEmpty) {
      return '';
    }

    if (purchase.productId == SubscriptionPlanType.noAds.dbValue) {
      return SubscriptionFormatters.planTitle(SubscriptionPlanType.noAds);
    }
    if (purchase.productId == SubscriptionPlanType.premium.dbValue) {
      return SubscriptionFormatters.planTitle(SubscriptionPlanType.premium);
    }
    return purchase.productId;
  }

  /// Whether the row has a billing period or an auto-renewal marker.
  static bool _hasDetails(PendingPurchaseEntity purchase) {
    return purchase.subscriptionInterval != null || purchase.isAutoRenewal;
  }
}

/// Billing period and auto-renewal marker of a subscription row.
class _HistoryDetails extends StatelessWidget {
  /// Purchase being described.
  final PendingPurchaseEntity purchase;

  /// Color of the billing period text.
  final Color detailsColor;

  /// Background color of the auto-renewal badge.
  final Color badgeColor;

  /// Text color of the auto-renewal badge.
  final Color badgeTextColor;

  const _HistoryDetails({
    required this.purchase,
    required this.detailsColor,
    required this.badgeColor,
    required this.badgeTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final SubscriptionInterval? interval = purchase.subscriptionInterval;

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        if (interval != null)
          Text(
            SubscriptionFormatters.intervalTitle(interval),
            style: AppFonts.normal12.copyWith(color: detailsColor),
          ),
        if (purchase.isAutoRenewal)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              LocaleKeys.subscription_history_auto_renewal.tr(),
              style: AppFonts.normal10.copyWith(
                color: badgeTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

/// Square preview of a purchased project.
class _HistoryThumbnail extends StatelessWidget {
  /// Image URL.
  final String url;

  /// Background color of the placeholder shown on error.
  final Color fallbackColor;

  /// Icon color of the placeholder shown on error.
  final Color iconColor;

  const _HistoryThumbnail({
    required this.url,
    required this.fallbackColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        url,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (BuildContext context, Object error, StackTrace? stack) {
          return Container(
            width: 48,
            height: 48,
            color: fallbackColor,
            alignment: Alignment.center,
            child: Icon(Icons.image_outlined, size: 22, color: iconColor),
          );
        },
      ),
    );
  }
}
