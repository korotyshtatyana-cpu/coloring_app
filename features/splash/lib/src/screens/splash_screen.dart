import 'package:core/core.dart';
import 'package:domain/domain.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:splash/src/screens/splash_content.dart';

import '../bloc/auth_bloc.dart';

/// Splash screen that checks authentication and navigates to the gallery.
@RoutePage()
class SplashScreen extends StatelessWidget {
  /// Creates a [SplashScreen].
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (context) => AuthBloc(
        checkAuthUseCase: appLocator<CheckAuthUseCase>(),
        signInUseCase: appLocator<SignInUseCase>(),
        signInSilentlyUseCase: appLocator<SignInSilentlyUseCase>(),
      )..add(const CheckAuth()),
      child: const SplashContent(),
    );
  }
}

