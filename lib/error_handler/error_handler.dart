import 'package:flutter/material.dart';

export 'error_handler.dart';
export 'error_messages.dart';
export 'error_reporting.dart';
export 'provider/app_error_handler_provider.dart';

class ErrorHandler {
  static void init(BuildContext context) {}

  static void handleError(
    Object error,
    StackTrace stackTrace, [
    String? customMessage,
  ]) {
    print('Error: $error');
    print('StackTrace: $stackTrace');
  }
}
