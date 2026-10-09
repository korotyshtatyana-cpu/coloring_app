part of 'settings_bloc.dart';

/// Settings loading status.
enum SettingsStatus {
  /// Initial state.
  initial,

  /// Loading settings.
  loading,

  /// Settings loaded.
  success,

  /// Error loading settings.
  failure,
}

/// State of the settings feature.
class SettingsState extends Equatable {
  /// Current status.
  final SettingsStatus status;

  /// Current locale language code.
  final String locale;

  /// Error message, if any.
  final String? error;

  /// Authenticated user profile.
  final UserEntity? user;

  /// Active subscription of the user, or `null` when there is none.
  final SubscriptionEntity? activeSubscription;

  /// Active subscription plan, or `null` when there is no active plan.
  final SubscriptionPlanType? planType;

  /// Whether the user permanently owns the No Ads plan.
  final bool noAdsPurchased;

  /// Whether the account was successfully deleted.
  final bool isDeleted;

  /// Creates a [SettingsState].
  const SettingsState({
    this.status = SettingsStatus.initial,
    this.locale = 'en-US',
    this.error,
    this.user,
    this.activeSubscription,
    this.planType,
    this.noAdsPurchased = false,
    this.isDeleted = false,
  });

  @override
  List<Object?> get props => <Object?>[
    status,
    locale,
    error,
    user,
    activeSubscription,
    planType,
    noAdsPurchased,
    isDeleted,
  ];

  /// Creates a copy with optional new values.
  SettingsState copyWith({
    SettingsStatus? status,
    String? locale,
    String? error,
    UserEntity? user,
    SubscriptionEntity? activeSubscription,
    SubscriptionPlanType? planType,
    bool? noAdsPurchased,
    bool? isDeleted,
  }) {
    return SettingsState(
      status: status ?? this.status,
      locale: locale ?? this.locale,
      error: error ?? this.error,
      user: user ?? this.user,
      activeSubscription: activeSubscription ?? this.activeSubscription,
      planType: planType ?? this.planType,
      noAdsPurchased: noAdsPurchased ?? this.noAdsPurchased,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
