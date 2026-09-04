import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:gallery/gallery.dart';

import '../bloc/auth_bloc.dart';
import '../widgets/login_button.dart';

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

class SplashContent extends StatelessWidget {
  /// Creates a [SplashContent].
  const SplashContent({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
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
      },
      child: Scaffold(
        backgroundColor: colors.primaryBg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 60,
                ),
                decoration: BoxDecoration(
                  color: colors.accentLight.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.brush,
                      size: 80,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      LocaleKeys.app_title.tr(),
                      style: AppFonts.extraBold36.copyWith(
                        color: colors.primaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  if (state.status == AuthStatus.loading) {
                    return CircularProgressIndicator(color: colors.secondaryBg);
                  }
                  if (state.status == AuthStatus.failure) {
                    return const LoginButton();
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
