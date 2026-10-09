import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../bloc/subscription_bloc.dart';
import '../widgets/purchase_history_section.dart';
import '../widgets/subscription_plan_card.dart';
import '../widgets/subscription_status_block.dart';

/// UI implementation of the subscription screen.
class SubscriptionContent extends StatelessWidget {
  /// Creates [SubscriptionContent].
  const SubscriptionContent({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final SubscriptionState state = context.watch<SubscriptionBloc>().state;

    return Scaffold(
      backgroundColor: colors.primaryBg,
      appBar: AppBar(
        centerTitle: false,
        toolbarHeight: 68,
        leadingWidth: 64,
        backgroundColor: colors.primaryBg,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16, top: 10, bottom: 10),
          child: ToolbarContainer(
            backgroundColor: colors.accentDark,
            isSquare: true,
            child: AppIconButton(
              size: 32,
              iconSize: 24,
              icon: Icon(Icons.arrow_back, color: colors.primaryBg),
              backgroundColor: Colors.transparent,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: Text(
          LocaleKeys.subscription_title.tr(),
          style: AppFonts.appBarTitle.copyWith(
            color: colors.primaryText,
            shadows: <Shadow>[],
          ),
        ),
      ),
      body: BlocListener<SubscriptionBloc, SubscriptionState>(
        listenWhen: (prev, curr) =>
            (prev.status != curr.status &&
                curr.status == SubscriptionStatus.failure) ||
            prev.purchaseUpdateId != curr.purchaseUpdateId,
        listener: (context, state) {
          if (state.status == SubscriptionStatus.failure) {
            ErrorDialog.show(
              context,
              message: state.error ?? LocaleKeys.something_went_wrong.tr(),
              onRetry: () =>
                  context.read<SubscriptionBloc>().add(const LoadSubscription()),
            );
            return;
          }
          final PurchaseUpdateEntity? update = state.purchaseUpdate;
          if (update != null) {
            _showPurchaseResult(context, update);
          }
        },
        child: state.status == SubscriptionStatus.loading
            ? Center(
                child: CircularProgressIndicator(color: colors.accentDark),
              )
            : ListView(
                padding: const EdgeInsets.all(24),
                children: <Widget>[
                  SubscriptionStatusBlock(
                    activeSubscription: state.activeSubscription,
                  ),
                  if (state.hasStalePending) ...<Widget>[
                    const SizedBox(height: 16),
                    const _StalePendingNotice(),
                  ],
                  const SizedBox(height: 24),
                  SubscriptionPlanCard(
                    title: LocaleKeys.subscription_no_ads_title.tr(),
                    description: LocaleKeys.subscription_no_ads_description.tr(),
                    accentColor: colors.averagePurple,
                    selectedPeriod: state.selectedNoAdsInterval,
                    isLoading: state.isPurchasing,
                    onPeriodChanged: (interval) => context
                        .read<SubscriptionBloc>()
                        .add(ChangePlanPeriod(
                          plan: SubscriptionPlanType.noAds,
                          interval: interval,
                        )),
                    onSubscribe: () => _onPurchase(
                      context,
                      SubscriptionPlanType.noAds,
                      state.selectedNoAdsInterval,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SubscriptionPlanCard(
                    title: LocaleKeys.subscription_premium_title.tr(),
                    description:
                        LocaleKeys.subscription_premium_description.tr(),
                    badge: LocaleKeys.subscription_premium_badge.tr(),
                    accentColor: colors.premiumGold,
                    selectedPeriod: state.selectedPremiumInterval,
                    isLoading: state.isPurchasing,
                    onPeriodChanged: (interval) => context
                        .read<SubscriptionBloc>()
                        .add(ChangePlanPeriod(
                          plan: SubscriptionPlanType.premium,
                          interval: interval,
                        )),
                    onSubscribe: () => _onPurchase(
                      context,
                      SubscriptionPlanType.premium,
                      state.selectedPremiumInterval,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _RestorePurchases(
                    onPressed: state.isPurchasing
                        ? null
                        : () => context
                            .read<SubscriptionBloc>()
                            .add(const RestorePurchases()),
                  ),
                  const SizedBox(height: 24),
                  PurchaseHistorySection(history: state.history),
                  const SizedBox(height: 24),
                  const _LegalFooter(),
                ],
              ),
      ),
    );
  }

  void _onPurchase(
    BuildContext context,
    SubscriptionPlanType plan,
    SubscriptionInterval interval,
  ) {
    final SubscriptionBloc bloc = context.read<SubscriptionBloc>();
    switch (plan) {
      case SubscriptionPlanType.noAds:
        bloc.add(PurchaseNoAds(interval: interval));
      case SubscriptionPlanType.premium:
        bloc.add(PurchasePremium(interval: interval));
    }
  }

  void _showPurchaseResult(BuildContext context, PurchaseUpdateEntity update) {
    switch (update.status) {
      case PurchaseUpdateStatus.success:
        ErrorDialog.show(
          context,
          title: LocaleKeys.purchase_success_title.tr(),
          message: update.isRestore
              ? LocaleKeys.purchase_restore_success.tr()
              : LocaleKeys.purchase_success_text.tr(),
        );
      case PurchaseUpdateStatus.pending:
        ErrorDialog.show(
          context,
          title: LocaleKeys.purchase_processing_title.tr(),
          message: LocaleKeys.purchase_processing_text.tr(),
        );
      case PurchaseUpdateStatus.failed:
        ErrorDialog.show(
          context,
          title: LocaleKeys.purchase_failed_title.tr(),
          message: LocaleKeys.purchase_failed_text.tr(),
        );
      case PurchaseUpdateStatus.canceled:
        return;
      case PurchaseUpdateStatus.empty:
        ErrorDialog.show(
          context,
          title: LocaleKeys.subscription_restore_button.tr(),
          message: LocaleKeys.purchase_restore_empty.tr(),
        );
    }
  }
}

class _StalePendingNotice extends StatelessWidget {
  const _StalePendingNotice();

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.secondaryBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentLight),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.info_outline, color: colors.accentDark, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              LocaleKeys.error_contact_support.tr(),
              style: AppFonts.normal14.copyWith(color: colors.primaryText),
            ),
          ),
        ],
      ),
    );
  }
}

class _RestorePurchases extends StatelessWidget {
  final VoidCallback? onPressed;

  const _RestorePurchases({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AppButton(
          text: LocaleKeys.subscription_restore_button.tr(),
          onPressed: onPressed,
        ),
        const SizedBox(height: 8),
        Text(
          LocaleKeys.subscription_restore_hint.tr(),
          style: AppFonts.normal12.copyWith(color: colors.secondaryText),
        ),
      ],
    );
  }
}

class _LegalFooter extends StatelessWidget {
  const _LegalFooter();

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        TextButton(
          onPressed: () {},
          child: Text(
            LocaleKeys.subscription_terms_of_service.tr(),
            style: AppFonts.normal12.copyWith(color: colors.secondaryText),
          ),
        ),
        Text(
          '•',
          style: AppFonts.normal12.copyWith(color: colors.secondaryText),
        ),
        TextButton(
          onPressed: () {},
          child: Text(
            LocaleKeys.subscription_privacy_policy.tr(),
            style: AppFonts.normal12.copyWith(color: colors.secondaryText),
          ),
        ),
      ],
    );
  }
}
