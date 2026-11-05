/// Outcome of a rewarded video attempt.
enum RewardedAdOutcome {
  /// The ad was watched to the end and the reward was earned.
  completed,

  /// The user closed the ad before earning the reward.
  dismissed,

  /// No ad could be shown, for example because the SDK is not configured,
  /// the device is offline or no ad was available.
  unavailable,
}
