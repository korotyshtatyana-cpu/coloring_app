/// Billing interval offered for a subscription plan.
enum SubscriptionInterval {
  /// One week.
  week('week'),

  /// One month.
  month('month'),

  /// One year.
  year('year');

  /// Value used as the suffix of a store product identifier.
  final String dbValue;

  const SubscriptionInterval(this.dbValue);

  /// Returns the interval matching the given [value].
  ///
  /// Falls back to [SubscriptionInterval.month] for unknown values.
  static SubscriptionInterval fromDb(String value) {
    for (final SubscriptionInterval interval in SubscriptionInterval.values) {
      if (interval.dbValue == value) {
        return interval;
      }
    }
    return SubscriptionInterval.month;
  }
}
