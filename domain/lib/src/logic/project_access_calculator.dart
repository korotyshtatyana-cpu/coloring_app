import '../../domain.dart';

/// Pure business logic deciding the access level of a project.
///
/// Implements the decision table from the monetization specification: access is
/// always evaluated from server-provided state and never from cached verdicts.
abstract final class ProjectAccessCalculator {
  /// Calculates the access level for [contour].
  ///
  /// Parameters:
  /// - [contour] — the project being opened.
  /// - [activeSubscription] — the user's currently active subscription, if any.
  /// - [noAdsPurchased] — whether the user permanently owns the No Ads plan.
  /// - [entitlement] — the user's entitlement for this specific project, if any.
  /// - [hasProgress] — whether the user already has strokes saved for the project.
  ///
  /// Individually purchased projects stay unlocked forever. Expired Premium
  /// subscribers keep `viewOnly` access to paid projects they already started.
  static ProjectAccess calculate({
    required ContourEntity contour,
    SubscriptionEntity? activeSubscription,
    bool noAdsPurchased = false,
    UserEntitlementEntity? entitlement,
    bool hasProgress = false,
  }) {
    if (_isPermanentPurchase(entitlement)) {
      return ProjectAccess.unlocked;
    }

    final SubscriptionPlanType? plan = activeSubscription?.isActiveNow() == true
        ? activeSubscription!.planType
        : null;
    final bool premium = plan == SubscriptionPlanType.premium;
    final bool hasAnyPlan = plan != null;

    switch (contour.accessType) {
      case ContourAccessType.free:
        return ProjectAccess.unlocked;

      case ContourAccessType.rewarded:
        if (hasAnyPlan || noAdsPurchased) {
          return ProjectAccess.unlocked;
        }
        if (_isRewardedUnlock(entitlement)) {
          return ProjectAccess.unlocked;
        }
        return ProjectAccess.locked;

      case ContourAccessType.paid:
        if (premium) {
          return ProjectAccess.unlocked;
        }
        return hasProgress ? ProjectAccess.viewOnly : ProjectAccess.locked;
    }
  }

  /// Whether [entitlement] is an individual purchase that is still valid.
  static bool _isPermanentPurchase(UserEntitlementEntity? entitlement) {
    return entitlement != null &&
        entitlement.type == EntitlementType.purchase &&
        entitlement.isActive();
  }

  /// Whether [entitlement] is an unexpired rewarded-video unlock.
  static bool _isRewardedUnlock(UserEntitlementEntity? entitlement) {
    return entitlement != null &&
        entitlement.type == EntitlementType.rewardedUnlock &&
        entitlement.isActive();
  }
}
