/// Reason a project entitlement was granted to the user.
enum EntitlementType {
  /// The project was bought individually and stays unlocked forever.
  ///
  /// Mapped to the `purchase` database value.
  purchase('purchase'),

  /// The project was unlocked by watching a rewarded video.
  ///
  /// Mapped to the `rewarded_unlock` database value.
  rewardedUnlock('rewarded_unlock'),

  /// The project is unlocked through an active subscription.
  ///
  /// Mapped to the `subscription_access` database value.
  subscriptionAccess('subscription_access');

  /// Value stored in the database `user_entitlements.type` column.
  final String dbValue;

  const EntitlementType(this.dbValue);

  /// Returns the entitlement type matching the given database [value].
  ///
  /// Returns `null` when [value] is not recognized.
  static EntitlementType? fromDb(String value) {
    for (final EntitlementType type in EntitlementType.values) {
      if (type.dbValue == value) {
        return type;
      }
    }
    return null;
  }
}
