import 'package:flutter/material.dart';

/// Helper for responsive UI decisions.
abstract final class ResponsiveHelper {
  /// Standard breakpoint for tablets (600 logical pixels).
  static const double tabletBreakpoint = 600.0;

  /// Returns true if the device is a tablet based on the shortest side of the
  /// screen.
  static bool isTablet(BuildContext context) {
    return MediaQuery.sizeOf(context).shortestSide >= tabletBreakpoint;
  }
}
