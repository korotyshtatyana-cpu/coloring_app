part of 'auth_bloc.dart';

/// Authentication status values.
enum AuthStatus {
  /// Initial state before any action.
  initial,

  /// Loading authentication state.
  loading,

  /// Authentication successful.
  success,

  /// Authentication failed.
  failure,
}

/// State of the authentication feature.
class AuthState extends Equatable {
  /// Current authentication status.
  final AuthStatus status;

  /// Whether the user is authenticated.
  final bool isAuthenticated;

  /// Authenticated user, if any.
  final UserEntity? user;

  /// Error message, if any.
  final String? error;

  /// Creates an [AuthState].
  const AuthState({
    this.status = AuthStatus.initial,
    this.isAuthenticated = false,
    this.user,
    this.error,
  });

  @override
  List<Object?> get props => <Object?>[status, isAuthenticated, user, error];

  /// Creates a copy with optional new values.
  AuthState copyWith({
    AuthStatus? status,
    bool? isAuthenticated,
    UserEntity? user,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      error: error ?? this.error,
    );
  }
}
