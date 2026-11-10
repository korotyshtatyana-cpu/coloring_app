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

  /// Store prices of the No Ads base plans by billing interval.
  final Map<SubscriptionInterval, String> noAdsPrices;

  /// Store prices of the Premium base plans by billing interval.
  final Map<SubscriptionInterval, String> premiumPrices;

  /// Whether a purchase or restore is currently in progress.
  final bool isPurchasing;

  /// Whether already loaded content is being refreshed in the background.
  ///
  /// When `true`, the screen keeps showing the current data instead of
  /// replacing it with a full-page spinner.
  final bool isRefreshing;

  /// Latest purchase or restore outcome, shown as feedback by the UI.
  final PurchaseUpdateEntity? purchaseUpdate;

  /// Monotonic identifier bumped on every purchase update.
  ///
  /// Lets the UI react to repeated updates with equal content.
  final int purchaseUpdateId;

  /// Whether an unresolved purchase older than 24 hours exists.
  final bool hasStalePending;

  /// Email of the current user, used to prefill the feedback form.
  final String? userEmail;

  /// Error message, if any.
  final String? error;

  /// Creates a [SubscriptionState].
  const SubscriptionState({
    this.status = SubscriptionStatus.initial,
    this.activeSubscription,
    this.history = const <PendingPurchaseEntity>[],
    this.selectedNoAdsInterval = SubscriptionInterval.month,
    this.selectedPremiumInterval = SubscriptionInterval.month,
    this.noAdsPrices = const <SubscriptionInterval, String>{},
    this.premiumPrices = const <SubscriptionInterval, String>{},
    this.isPurchasing = false,
    this.isRefreshing = false,
    this.purchaseUpdate,
    this.purchaseUpdateId = 0,
    this.hasStalePending = false,
    this.userEmail,
    this.error,
  });

  @override
  List<Object?> get props => <Object?>[
    status,
    activeSubscription,
    history,
    selectedNoAdsInterval,
    selectedPremiumInterval,
    noAdsPrices,
    premiumPrices,
    isPurchasing,
    isRefreshing,
    purchaseUpdate,
    purchaseUpdateId,
    hasStalePending,
    userEmail,
    error,
  ];

  /// Creates a copy with optional new values.
  SubscriptionState copyWith({
    SubscriptionStatus? status,
    SubscriptionEntity? activeSubscription,
    bool clearActiveSubscription = false,
    List<PendingPurchaseEntity>? history,
    SubscriptionInterval? selectedNoAdsInterval,
    SubscriptionInterval? selectedPremiumInterval,
    Map<SubscriptionInterval, String>? noAdsPrices,
    Map<SubscriptionInterval, String>? premiumPrices,
    bool? isPurchasing,
    bool? isRefreshing,
    PurchaseUpdateEntity? purchaseUpdate,
    int? purchaseUpdateId,
    bool? hasStalePending,
    String? userEmail,
    String? error,
  }) {
    return SubscriptionState(
      status: status ?? this.status,
      activeSubscription: clearActiveSubscription
          ? null
          : activeSubscription ?? this.activeSubscription,
      history: history ?? this.history,
      selectedNoAdsInterval:
          selectedNoAdsInterval ?? this.selectedNoAdsInterval,
      selectedPremiumInterval:
          selectedPremiumInterval ?? this.selectedPremiumInterval,
      noAdsPrices: noAdsPrices ?? this.noAdsPrices,
      premiumPrices: premiumPrices ?? this.premiumPrices,
      isPurchasing: isPurchasing ?? this.isPurchasing,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      purchaseUpdate: purchaseUpdate ?? this.purchaseUpdate,
      purchaseUpdateId: purchaseUpdateId ?? this.purchaseUpdateId,
      hasStalePending: hasStalePending ?? this.hasStalePending,
      userEmail: userEmail ?? this.userEmail,
      error: error ?? this.error,
    );
  }
}
