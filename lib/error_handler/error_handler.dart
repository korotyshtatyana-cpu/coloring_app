import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

import 'error_messages.dart';
import 'error_reporting.dart';

export 'error_messages.dart';
export 'error_reporting.dart';
export 'provider/app_error_handler_provider.dart';

/// Application-wide error handler that logs, reports and optionally shows a UI.
///
/// Use [report] from BLoCs and other business logic to log and report an error
/// without displaying any UI. Use [showErrorDialog] from screens to present
/// errors to the user. Use [handleError] as a convenience for one-off errors
/// where the same call should log, report and show a dialog.
class ErrorHandler {
  static GlobalKey<NavigatorState>? _navigatorKey;

  /// Initializes the error handler with the given [navigatorKey].
  ///
  /// The navigator key is used by [handleError] as a fallback to find a
  /// [BuildContext] when no context is provided.
  static void init(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }

  /// Logs and reports an [error] without showing any UI.
  ///
  /// This is the preferred method for BLoCs: they should report errors and
  /// emit a failure state, letting the screen decide how to present the error.
  static void report(
    Object error,
    StackTrace stackTrace, {
    String? message,
  }) {
    ErrorReporting.report(error, stackTrace, message);
  }

  /// Shows an error dialog with the given [message].
  ///
  /// If [context] is provided, the dialog is shown on that context. Otherwise,
  /// the dialog falls back to the context obtained from the registered
  /// [navigatorKey]. If no context is available, the error is only reported.
  static void showErrorDialog(
    String message, {
    BuildContext? context,
    String? retryLabel,
    VoidCallback? onRetry,
  }) {
    final BuildContext? effectiveContext =
        context ?? _navigatorKey?.currentState?.overlay?.context;
    if (effectiveContext == null) {
      return;
    }

    ErrorDialog.show(
      effectiveContext,
      message: message,
      retryLabel: retryLabel,
      onRetry: onRetry,
    );
  }

  /// Logs, reports and shows an error dialog for the given [error].
  ///
  /// Prefer using [report] in business logic and [showErrorDialog] in UI code
  /// for better separation of concerns. This method is kept as a convenience
  /// for code paths that do not have access to a [BuildContext].
  static void handleError(
    Object error,
    StackTrace stackTrace, [
    String? customMessage,
  ]) {
    report(error, stackTrace, message: customMessage);

    final String message = customMessage ?? ErrorMessages.getMessage(error);
    showErrorDialog(message);
  }

}
