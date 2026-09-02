import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gear_track/feature/auth/domain/usecases/check_auth_status.dart';
import 'package:gear_track/feature/auth/domain/usecases/login_with_email_password.dart';
import 'package:gear_track/feature/auth/domain/usecases/send_password_reset.dart';
import 'package:gear_track/feature/auth/domain/usecases/sign_out.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginWithEmailPassword loginWithEmailPassword;
  final SendPasswordReset sendPasswordReset;
  final CheckAuthStatus checkAuthStatus;
  final SignOut signOut;

  AuthBloc({
    required this.loginWithEmailPassword,
    required this.sendPasswordReset,
    required this.checkAuthStatus,
    required this.signOut,
  }) : super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheck);
    on<AuthLoginRequested>(_onLogin);
    on<AuthForgotPasswordRequested>(_onForgotPassword);
    on<AuthSignOutRequested>(_onSignOut);
  }

  Future<void> _onCheck(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await checkAuthStatus();
    result.fold(
      (failure) => emit(const Unauthenticated()),
      (isAuthenticated) {
        if (isAuthenticated) {
          emit(Authenticated(user: FirebaseAuth.instance.currentUser));
        } else {
          emit(const Unauthenticated());
        }
      },
    );
  }

  Future<void> _onLogin(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Logging in...'));
    final result = await loginWithEmailPassword(
      email: event.email,
      password: event.password,
    );

    result.fold(
      (failure) => emit(AuthFailureState(failure.message)),
      (user) => emit(Authenticated(user: user)),
    );
  }

  Future<void> _onForgotPassword(
    AuthForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Sending reset link...'));
    final result = await sendPasswordReset(email: event.email);

    result.fold(
      (failure) => emit(AuthFailureState(failure.message)),
      (_) => emit(AuthPasswordResetSentState(email: event.email)),
    );
  }

  Future<void> _onSignOut(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Signing out...'));
    await signOut();
    emit(const Unauthenticated());
  }
}
