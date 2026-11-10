import '../entities/pending_purchase_entity.dart';

/// Whether the user should still be warned about a failed subscription setup.
///
/// An old pending subscription row is superseded as soon as a newer
/// subscription period was paid, even if that subscription has already
/// expired. Keeping the notice hidden afterwards avoids resurrecting a stale
/// warning from an earlier failed attempt.
bool hasStaleSubscriptionPending({
  required Iterable<PendingPurchaseEntity> pending,
  required Iterable<PendingPurchaseEntity> history,
  required DateTime now,
  required Duration threshold,
  DateTime? activeSubscriptionStartedAt,
}) {
  DateTime? latestSuccessfulStart;
  for (final PendingPurchaseEntity purchase in history) {
    if (!purchase.isSubscription ||
        purchase.status != PendingPurchaseStatus.resolved) {
      continue;
    }
    if (latestSuccessfulStart == null ||
        purchase.createdAt.isAfter(latestSuccessfulStart)) {
      latestSuccessfulStart = purchase.createdAt;
    }
  }
  if (activeSubscriptionStartedAt != null &&
      (latestSuccessfulStart == null ||
          activeSubscriptionStartedAt.isAfter(latestSuccessfulStart))) {
    latestSuccessfulStart = activeSubscriptionStartedAt;
  }

  return pending.any((PendingPurchaseEntity purchase) {
    // Only a subscription that never activated is worth reporting.
    if (!purchase.isSubscription ||
        now.difference(purchase.createdAt) <= threshold) {
      return false;
    }
    // A newer successful subscription supersedes the failed attempt.
    return latestSuccessfulStart == null ||
        purchase.createdAt.isAfter(latestSuccessfulStart);
  });
}
