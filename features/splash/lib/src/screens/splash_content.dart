import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:gallery/gallery.dart';

import '../bloc/auth_bloc.dart';
import '../widgets/login_button.dart';
import '../widgets/animated_logo.dart';

class SplashContent extends StatefulWidget {
  /// Creates a [SplashContent].
  const SplashContent({super.key});

  @override
  State<SplashContent> createState() => _SplashContentState();
}

class _SplashContentState extends State<SplashContent> {
  bool _animationFinished = false;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        _checkNavigation(state);

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
              AnimatedLogo(
                onFinished: () {
                  setState(() => _animationFinished = true);
                  _checkNavigation(context.read<AuthBloc>().state);
                },
              ),
              const SizedBox(height: 48),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
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

  void _checkNavigation(AuthState state) {
    if (_animationFinished &&
        state.status == AuthStatus.success &&
        state.isAuthenticated) {
      context.router.replace(const GalleryRoute());
    }
  }
}
