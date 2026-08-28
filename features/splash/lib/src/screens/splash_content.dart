import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:gallery/gallery.dart';

import '../bloc/auth_bloc.dart';
import '../widgets/splash_status_indicator.dart';
import '../widgets/splash_title.dart';

/// UI implementation of the splash screen.
class SplashContent extends StatelessWidget {
  /// Creates a [SplashContent].
  const SplashContent({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return BlocListener<AuthBloc, AuthState>(
      listener: (BuildContext context, AuthState state) => _onAuthStateChanged(context, state),
      child: Scaffold(
        backgroundColor: colors.primaryBg,
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SplashTitle(),
              SizedBox(height: 32),
              SplashStatusIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  void _onAuthStateChanged(BuildContext context, AuthState state) {
    if (state.status == AuthStatus.success && state.isAuthenticated) {
      context.router.replace(const GalleryRoute());
      return;
    }

    if (state.status == AuthStatus.success && !state.isAuthenticated) {
      context.read<AuthBloc>().add(const SignInSilently());
      return;
    }

    if (state.status == AuthStatus.failure) {
      ErrorDialog.show(
        context,
        message: state.error ?? LocaleKeys.something_went_wrong.tr(),
      );
    }
  }
}
