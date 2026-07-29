part of 'auth_bloc.dart';

/// Base class for authentication events.
abstract class AuthEvent extends Equatable {
  /// Creates an [AuthEvent].
  const AuthEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Requests a check of the current authentication state.
class CheckAuth extends AuthEvent {
  /// Creates a [CheckAuth] event.
  const CheckAuth();
}

/// Requests sign in.
class SignIn extends AuthEvent {
  /// Creates a [SignIn] event.
  const SignIn();
}

/// Requests silent sign in using a previously authorized platform account.
class SignInSilently extends AuthEvent {
  /// Creates a [SignInSilently] event.
  const SignInSilently();
}

/// Requests sign out.
class SignOut extends AuthEvent {
  /// Creates a [SignOut] event.
  const SignOut();
}
