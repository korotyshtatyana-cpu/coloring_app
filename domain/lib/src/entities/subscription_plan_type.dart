/// Subscription plan purchased by the user.
enum SubscriptionPlanType {
  /// Plan that removes ads from the app.
  ///
  /// Mapped to the `no_ads` database value.
  noAds('no_ads'),

  /// Plan that removes ads and unlocks all paid projects.
  ///
  /// Mapped to the `premium` database value.
  premium('premium');

  /// Value stored in the database `subscriptions.plan_type` column.
  final String dbValue;

  const SubscriptionPlanType(this.dbValue);

  /// Returns the plan matching the given database [value].
  ///
  /// Falls back to [SubscriptionPlanType.premium] for unknown values, so an
  /// unrecognized plan grants the wider access rather than the narrower one.
  static SubscriptionPlanType fromDb(String value) {
    for (final SubscriptionPlanType type in SubscriptionPlanType.values) {
      if (type.dbValue == value) {
        return type;
      }
    }
    return SubscriptionPlanType.premium;
  }
}
