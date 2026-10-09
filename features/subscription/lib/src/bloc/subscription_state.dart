part of 'subscription_bloc.dart';

/// Loading status of the subscription screen.
enum SubscriptionStatus {
  /// Initial state.
  initial,

  /// Loading the subscription and history.
  loading,

  /// Data loaded successfully.
  success,

  /// Error loading data.
  failure,
}

/// State of the subscription feature.
class SubscriptionState extends Equatable {
  /// Current loading status.
  final SubscriptionStatus status;

  /// Active subscription, or `null` when the user has none.
  final SubscriptionEntity? activeSubscription;

  /// Resolved purchases, most recent first.
  final List<PendingPurchaseEntity> history;

  /// Selected billing interval of the No Ads plan.
  final SubscriptionInterval selectedNoAdsInterval;

  /// Selected billing interval of the Premium plan.
  final SubscriptionInterval selectedPremiumInterval;

  /// Whether a purchase or restore is currently in progress.
  final bool isPurchasing;

  /// Latest purchase or restore outcome, shown as feedback by the UI.
  final PurchaseUpdateEntity? purchaseUpdate;

  /// Monotonic identifier bumped on every purchase update.
  ///
  /// Lets the UI react to repeated updates with equal content.
  final int purchaseUpdateId;

  /// Whether an unresolved purchase older than 24 hours exists.
  final bool hasStalePending;

  /// Error message, if any.
  final String? error;

  /// Creates a [SubscriptionState].
  const SubscriptionState({
    this.status = SubscriptionStatus.initial,
    this.activeSubscription,
    this.history = const <PendingPurchaseEntity>[],
    this.selectedNoAdsInterval = SubscriptionInterval.month,
    this.selectedPremiumInterval = SubscriptionInterval.month,
    this.isPurchasing = false,
    this.purchaseUpdate,
    this.purchaseUpdateId = 0,
    this.hasStalePending = false,
    this.error,
  });

  @override
  List<Object?> get props => <Object?>[
    status,
    activeSubscription,
    history,
    selectedNoAdsInterval,
    selectedPremiumInterval,
    isPurchasing,
    purchaseUpdate,
    purchaseUpdateId,
    hasStalePending,
    error,
  ];

  /// Creates a copy with optional new values.
  SubscriptionState copyWith({
    SubscriptionStatus? status,
    SubscriptionEntity? activeSubscription,
    List<PendingPurchaseEntity>? history,
    SubscriptionInterval? selectedNoAdsInterval,
    SubscriptionInterval? selectedPremiumInterval,
    bool? isPurchasing,
    PurchaseUpdateEntity? purchaseUpdate,
    int? purchaseUpdateId,
    bool? hasStalePending,
    String? error,
  }) {
    return SubscriptionState(
      status: status ?? this.status,
      activeSubscription: activeSubscription ?? this.activeSubscription,
      history: history ?? this.history,
      selectedNoAdsInterval: selectedNoAdsInterval ?? this.selectedNoAdsInterval,
      selectedPremiumInterval: selectedPremiumInterval ?? this.selectedPremiumInterval,
      isPurchasing: isPurchasing ?? this.isPurchasing,
      purchaseUpdate: purchaseUpdate ?? this.purchaseUpdate,
      purchaseUpdateId: purchaseUpdateId ?? this.purchaseUpdateId,
      hasStalePending: hasStalePending ?? this.hasStalePending,
      error: error ?? this.error,
    );
  }
}
