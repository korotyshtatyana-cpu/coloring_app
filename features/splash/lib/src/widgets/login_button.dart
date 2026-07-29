import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';

/// Button that triggers sign in via the platform identity provider.
class LoginButton extends StatelessWidget {
  /// Creates a [LoginButton].
  const LoginButton({super.key});

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      text: LocaleKeys.sign_in.tr(),
      onPressed: () {
        context.read<AuthBloc>().add(const SignIn());
      },
      width: 240,
    );
  }
}
