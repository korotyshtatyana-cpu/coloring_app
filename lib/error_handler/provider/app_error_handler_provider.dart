import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../error_handler.dart';

class AppErrorHandlerProvider extends StatefulWidget {
  final Widget child;

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
      ErrorHandler.handleError(
        details.exception,
        details.stack ?? StackTrace.current,
      );
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
    ErrorHandler.handleError(error, stackTrace);
    super.onError(bloc, error, stackTrace);
  }
}
