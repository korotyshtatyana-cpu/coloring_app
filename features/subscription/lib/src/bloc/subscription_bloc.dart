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
  final BuySubscriptionUseCase _buySubscriptionUseCase;
  final RestorePurchasesUseCase _restorePurchasesUseCase;
  final WatchPurchaseUpdatesUseCase _watchPurchaseUpdatesUseCase;

  StreamSubscription<PurchaseUpdateEntity>? _updatesSubscription;

  /// Creates a [SubscriptionBloc] with the required use cases.
  SubscriptionBloc({
    required this._getCurrentUserUseCase,
    required this._getActiveSubscriptionUseCase,
    required this._getPurchaseHistoryUseCase,
    required this._getPendingPurchasesUseCase,
    required this._buySubscriptionUseCase,
    required this._restorePurchasesUseCase,
    required this._watchPurchaseUpdatesUseCase,
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
    try {
      emit(state.copyWith(status: SubscriptionStatus.loading, error: null));

      final UserEntity? user = await _getCurrentUserUseCase.execute();
      if (user == null) {
        emit(state.copyWith(status: SubscriptionStatus.success));
        return;
      }

      final SubscriptionEntity? subscription =
          await _getActiveSubscriptionUseCase.execute(user.id);
      final List<PendingPurchaseEntity> history =
          await _getPurchaseHistoryUseCase.execute(user.id);
      final List<PendingPurchaseEntity> pending =
          await _getPendingPurchasesUseCase.execute(user.id);

      final bool hasStalePending = pending.any(
        (PendingPurchaseEntity purchase) =>
            DateTime.now().difference(purchase.createdAt) >
            Constants.stalePendingPurchaseThreshold,
      );

      emit(state.copyWith(
        status: SubscriptionStatus.success,
        activeSubscription: subscription,
        history: history,
        hasStalePending: hasStalePending,
      ));
    } catch (e, stackTrace) {
      ErrorHandler.report(e, stackTrace);
      emit(state.copyWith(
        status: SubscriptionStatus.failure,
        error: e.toString(),
      ));
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
      // The store flow only starts here; the outcome arrives through
      // [WatchPurchaseUpdatesUseCase].
      await _buySubscriptionUseCase.execute(
        BuySubscriptionParams(plan: plan, interval: interval),
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
    emit(state.copyWith(
      isPurchasing: false,
      purchaseUpdate: event.update,
      purchaseUpdateId: state.purchaseUpdateId + 1,
    ));

    if (event.update.status == PurchaseUpdateStatus.success) {
      add(const LoadSubscription());
    }
  }
}
