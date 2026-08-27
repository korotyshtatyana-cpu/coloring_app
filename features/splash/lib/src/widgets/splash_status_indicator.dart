import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';
import 'login_button.dart';

/// Loading indicator or login button based on auth status.
class SplashStatusIndicator extends StatelessWidget {
  /// Creates a [SplashStatusIndicator].
  const SplashStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (BuildContext context, AuthState state) {
        if (state.status == AuthStatus.loading) {
          return CircularProgressIndicator(color: colors.secondaryBg);
        }
        if (state.status == AuthStatus.failure) {
          return const LoginButton();
        }
        return const SizedBox.shrink();
      },
    );
  }
}
