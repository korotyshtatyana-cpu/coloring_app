import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../error_reporting.dart';

/// Widget that installs global error handlers for the application.
class AppErrorHandlerProvider extends StatefulWidget {
  /// Child widget.
  final Widget child;

  /// Creates an [AppErrorHandlerProvider].
  const AppErrorHandlerProvider({
    super.key,
    required this.child,
  });

  @override
  State<AppErrorHandlerProvider> createState() =>
      _AppErrorHandlerProviderState();
}

class _AppErrorHandlerProviderState extends State<AppErrorHandlerProvider> {
  @override
  void initState() {
    super.initState();
    _setupErrorHandlers();
  }

  void _setupErrorHandlers() {
    FlutterError.onError = (FlutterErrorDetails details) {
      ErrorReporting.report(
        details.exception,
        details.stack ?? StackTrace.current,
      );
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stackTrace) {
      ErrorReporting.report(error, stackTrace);
      return true;
    };

    Bloc.observer = _AppBlocObserver();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _AppBlocObserver extends BlocObserver {
  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    ErrorReporting.report(error, stackTrace);
    super.onError(bloc, error, stackTrace);
  }
}
