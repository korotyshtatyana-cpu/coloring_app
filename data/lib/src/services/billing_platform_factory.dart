import 'dart:io';

import 'apple_billing_platform.dart';
import 'billing_platform.dart';
import 'google_play_billing_platform.dart';

/// Creates the [BillingPlatform] matching the current operating system.
abstract final class BillingPlatformFactory {
  /// Returns the billing platform for this device.
  ///
  /// Android uses the fully implemented [GooglePlayBillingPlatform]; iOS
  /// returns the [AppleBillingPlatform] stub, which throws until it is
  /// implemented. Other platforms are not supported.
  static BillingPlatform create() {
    if (Platform.isAndroid) {
      return GooglePlayBillingPlatform();
    }
    if (Platform.isIOS) {
      return AppleBillingPlatform();
    }
    throw UnsupportedError('Billing is not supported on this platform');
  }
}
