import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Debug-only button visible in [kDebugMode] to test Crashlytics error reports.
class DebugCrashButton extends StatelessWidget {
  /// Creates a [DebugCrashButton].
  const DebugCrashButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    return Column(
      children: <Widget>[
        const SizedBox(height: 16),
        AppButton(
          text: 'Debug: Test Crashlytics Error',
          color: Colors.orange,
          onPressed: () {
            appLocator<CrashReporter>().recordError(
              StateError('Test Crashlytics Error'),
              StackTrace.current,
              reason: 'Debug test crash button pressed',
              fatal: true,
            );
          },
        ),
      ],
    );
  }
}
