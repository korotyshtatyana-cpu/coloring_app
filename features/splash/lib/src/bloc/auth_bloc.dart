import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/core.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// BLoC responsible for authentication state and actions.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final CheckAuthUseCase _checkAuthUseCase;
  final SignInUseCase _signInUseCase;
  final SignInSilentlyUseCase _signInSilentlyUseCase;

  /// Creates an [AuthBloc] with the required use cases.
  AuthBloc({
    required CheckAuthUseCase checkAuthUseCase,
    required SignInUseCase signInUseCase,
    required SignInSilentlyUseCase signInSilentlyUseCase,
  })  : _checkAuthUseCase = checkAuthUseCase,
        _signInUseCase = signInUseCase,
        _signInSilentlyUseCase = signInSilentlyUseCase,
        super(const AuthState()) {
    on<CheckAuth>(_onCheckAuth);
    on<SignIn>(_onSignIn);
    on<SignInSilently>(_onSignInSilently);
    on<SignOut>(_onSignOut);
  }

  Future<void> _onCheckAuth(CheckAuth event, Emitter<AuthState> emit) async {
    try {
      emit(state.copyWith(status: AuthStatus.loading, error: null));
      final isAuthenticated = await _checkAuthUseCase.execute();
      emit(state.copyWith(
        status: AuthStatus.success,
        isAuthenticated: isAuthenticated,
      ));
    } catch (e, stackTrace) {
      ErrorHandler.report(e, stackTrace);
      emit(state.copyWith(
        status: AuthStatus.failure,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onSignIn(SignIn event, Emitter<AuthState> emit) async {
    try {
      emit(state.copyWith(status: AuthStatus.loading, error: null));
      final user = await _signInUseCase.execute();
      emit(state.copyWith(
        status: AuthStatus.success,
        isAuthenticated: true,
        user: user,
      ));
    } catch (e, stackTrace) {
      ErrorHandler.report(e, stackTrace);
      emit(state.copyWith(
        status: AuthStatus.failure,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onSignInSilently(
    SignInSilently event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(state.copyWith(status: AuthStatus.loading, error: null));
      final user = await _signInSilentlyUseCase.execute();
      emit(state.copyWith(
        status: AuthStatus.success,
        isAuthenticated: true,
        user: user,
      ));
    } catch (e, stackTrace) {
      ErrorHandler.report(e, stackTrace);
      emit(state.copyWith(
        status: AuthStatus.failure,
        isAuthenticated: false,
        user: null,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onSignOut(SignOut event, Emitter<AuthState> emit) async {
    emit(state.copyWith(
      status: AuthStatus.success,
      isAuthenticated: false,
      user: null,
    ));
  }
}
