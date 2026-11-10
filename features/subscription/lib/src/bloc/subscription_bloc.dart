import 'dart:async';

import 'package:core/core.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';

part 'subscription_event.dart';
part 'subscription_state.dart';

/// BLoC responsible for the subscription screen.
class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final GetActiveSubscriptionUseCase _getActiveSubscriptionUseCase;
  final GetPurchaseHistoryUseCase _getPurchaseHistoryUseCase;
  final GetPendingPurchasesUseCase _getPendingPurchasesUseCase;
  final GetSubscriptionPricesUseCase _getSubscriptionPricesUseCase;
  final BuySubscriptionUseCase _buySubscriptionUseCase;
  final RestorePurchasesUseCase _restorePurchasesUseCase;
  final WatchPurchaseUpdatesUseCase _watchPurchaseUpdatesUseCase;
  final AppLogger _logger;

  StreamSubscription<PurchaseUpdateEntity>? _updatesSubscription;

  /// Creates a [SubscriptionBloc] with the required use cases.
  SubscriptionBloc({
    required this._getCurrentUserUseCase,
    required this._getActiveSubscriptionUseCase,
    required this._getPurchaseHistoryUseCase,
    required this._getPendingPurchasesUseCase,
    required this._getSubscriptionPricesUseCase,
    required this._buySubscriptionUseCase,
    required this._restorePurchasesUseCase,
    required this._watchPurchaseUpdatesUseCase,
    required this._logger,
  }) : super(const SubscriptionState()) {
    on<LoadSubscription>(_onLoadSubscription);
    on<ChangePlanPeriod>(_onChangePlanPeriod);
    on<PurchaseNoAds>(_onPurchaseNoAds);
    on<PurchasePremium>(_onPurchasePremium);
    on<RestorePurchases>(_onRestorePurchases);
    on<PurchaseUpdated>(_onPurchaseUpdated);

    _updatesSubscription = _watchPurchaseUpdatesUseCase.execute().listen(
      (PurchaseUpdateEntity update) => add(PurchaseUpdated(update)),
    );
  }

  @override
  Future<void> close() async {
    await _updatesSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadSubscription(
    LoadSubscription event,
    Emitter<SubscriptionState> emit,
  ) async {
    // Keep already loaded content on screen. A reload triggered by a purchase
    // should refresh the data in place instead of replacing the whole page
    // with a spinner and losing the scroll position.
    final bool hasLoadedData = state.status == SubscriptionStatus.success;
    final Map<SubscriptionInterval, String> cachedNoAdsPrices =
        state.noAdsPrices;
    final Map<SubscriptionInterval, String> cachedPremiumPrices =
        state.premiumPrices;
    try {
      emit(
        state.copyWith(
          status: hasLoadedData
              ? SubscriptionStatus.success
              : SubscriptionStatus.loading,
          isRefreshing: hasLoadedData,
          error: null,
        ),
      );

      // Store prices only change when the Play Console configuration changes,
      // so reuse the values loaded with the first request.
      Map<SubscriptionInterval, String> noAdsPrices = cachedNoAdsPrices;
      Map<SubscriptionInterval, String> premiumPrices = cachedPremiumPrices;
      if (noAdsPrices.isEmpty || premiumPrices.isEmpty) {
        final Map<SubscriptionInterval, String> loadedNoAdsPrices =
            <SubscriptionInterval, String>{};
        final Map<SubscriptionInterval, String> loadedPremiumPrices =
            <SubscriptionInterval, String>{};
        try {
          final List<SubscriptionPriceEntity> prices =
              await _getSubscriptionPricesUseCase.execute();
          for (final SubscriptionPriceEntity price in prices) {
            if (price.plan == SubscriptionPlanType.premium) {
              loadedPremiumPrices[price.interval] = price.price;
            } else {
              loadedNoAdsPrices[price.interval] = price.price;
            }
          }
        } catch (e) {
          // Prices are informative only; the screen still works without them.
          _logger.warning(
            '[Monetization] Failed to load subscription prices: $e',
          );
        }
        noAdsPrices = loadedNoAdsPrices;
        premiumPrices = loadedPremiumPrices;
      }

      final UserEntity? user = await _getCurrentUserUseCase.execute();
      if (user == null) {
        emit(
          state.copyWith(
            status: SubscriptionStatus.success,
            isRefreshing: false,
            clearActiveSubscription: true,
            noAdsPrices: noAdsPrices,
            premiumPrices: premiumPrices,
          ),
        );
        return;
      }

      final SubscriptionEntity? subscription =
          await _getActiveSubscriptionUseCase.execute(user.id);
      final List<PendingPurchaseEntity> history =
          await _getPurchaseHistoryUseCase.execute(user.id);
      final List<PendingPurchaseEntity> pending =
          await _getPendingPurchasesUseCase.execute(user.id);

      final DateTime now = DateTime.now();
      final bool hasActiveSubscription =
          subscription?.isActiveNow(now) ?? false;
      final DateTime? activeSubscriptionStartedAt = hasActiveSubscription
          ? subscription?.startedAt
          : null;
      final bool hasStalePending = hasStaleSubscriptionPending(
        pending: pending,
        history: history,
        now: now,
        threshold: Constants.stalePendingPurchaseThreshold,
        activeSubscriptionStartedAt: activeSubscriptionStartedAt,
      );

      emit(
        state.copyWith(
          status: SubscriptionStatus.success,
          isRefreshing: false,
          activeSubscription: subscription,
          clearActiveSubscription: subscription == null,
          history: history,
          hasStalePending: hasStalePending,
          noAdsPrices: noAdsPrices,
          premiumPrices: premiumPrices,
          userEmail: user.email,
        ),
      );
    } catch (e, stackTrace) {
      ErrorHandler.report(e, stackTrace);
      if (hasLoadedData) {
        // A background refresh must not wipe a valid screen; keep the last
        // known data and let the next load retry.
        _logger.warning(
          '[Monetization] Failed to refresh subscription screen: $e',
        );
        emit(
          state.copyWith(
            status: SubscriptionStatus.success,
            isRefreshing: false,
            error: e.toString(),
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          status: SubscriptionStatus.failure,
          isRefreshing: false,
          error: e.toString(),
        ),
      );
    }
  }

  void _onChangePlanPeriod(
    ChangePlanPeriod event,
    Emitter<SubscriptionState> emit,
  ) {
    switch (event.plan) {
      case SubscriptionPlanType.noAds:
        emit(state.copyWith(selectedNoAdsInterval: event.interval));
      case SubscriptionPlanType.premium:
        emit(state.copyWith(selectedPremiumInterval: event.interval));
    }
  }

  Future<void> _onPurchaseNoAds(
    PurchaseNoAds event,
    Emitter<SubscriptionState> emit,
  ) {
    return _purchase(SubscriptionPlanType.noAds, event.interval, emit);
  }

  Future<void> _onPurchasePremium(
    PurchasePremium event,
    Emitter<SubscriptionState> emit,
  ) {
    return _purchase(SubscriptionPlanType.premium, event.interval, emit);
  }

  Future<void> _purchase(
    SubscriptionPlanType plan,
    SubscriptionInterval interval,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      emit(state.copyWith(isPurchasing: true, error: null));
      _logger.debug(
        '[Monetization] Subscription purchase initiated: '
        'product=${plan.dbValue}, basePlan=${interval.dbValue}',
      );
      final SubscriptionEntity? current = state.activeSubscription;
      final bool hasCurrent = current?.isActiveNow() ?? false;
      // The store flow only starts here; the outcome arrives through
      // [WatchPurchaseUpdatesUseCase].
      await _buySubscriptionUseCase.execute(
        BuySubscriptionParams(
          plan: plan,
          interval: interval,
          currentProductId: hasCurrent ? current?.productId : null,
          currentBasePlanId: hasCurrent ? current?.basePlanId : null,
        ),
      );
    } catch (e, stackTrace) {
      ErrorHandler.report(e, stackTrace);
      emit(state.copyWith(isPurchasing: false, error: e.toString()));
      add(
        PurchaseUpdated(
          PurchaseUpdateEntity(
            status: PurchaseUpdateStatus.failed,
            error: e.toString(),
          ),
        ),
      );
    }
  }

  Future<void> _onRestorePurchases(
    RestorePurchases event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      emit(state.copyWith(isPurchasing: true, error: null));
      await _restorePurchasesUseCase.execute();
    } catch (e, stackTrace) {
      ErrorHandler.report(e, stackTrace);
      emit(state.copyWith(isPurchasing: false, error: e.toString()));
      add(
        PurchaseUpdated(
          PurchaseUpdateEntity(
            status: PurchaseUpdateStatus.failed,
            isRestore: true,
            error: e.toString(),
          ),
        ),
      );
    }
  }

  void _onPurchaseUpdated(
    PurchaseUpdated event,
    Emitter<SubscriptionState> emit,
  ) {
    final bool isStillPurchasing =
        event.update.status == PurchaseUpdateStatus.pending;

    emit(
      state.copyWith(
        isPurchasing: isStillPurchasing,
        purchaseUpdate: event.update,
        purchaseUpdateId: state.purchaseUpdateId + 1,
      ),
    );

    // Only a successful purchase changes the subscription or the history.
    // Cancelling the store sheet, a store error, or an empty restore leaves
    // the screen data untouched, so a reload would only cause a pointless
    // refresh.
    if (event.update.status == PurchaseUpdateStatus.success) {
      add(const LoadSubscription());
    }
  }
}
