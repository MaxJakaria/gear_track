import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:gear_track/feature/auth/data/sources/auth_remote_data_source.dart';
import 'package:gear_track/feature/auth/domain/usecases/check_auth_status.dart';
import 'package:gear_track/feature/auth/domain/usecases/complete_session_login.dart';
import 'package:gear_track/feature/auth/domain/usecases/send_sign_in_link.dart';
import 'package:gear_track/feature/auth/domain/usecases/sign_out.dart';
import 'package:gear_track/feature/auth/domain/usecases/watch_session_approval.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SendSignInLink sendSignInLink;
  final WatchSessionApproval watchSessionApproval;
  final CompleteSessionLogin completeSessionLogin;
  final CheckAuthStatus checkAuthStatus;
  final SignOut signOut;

  static const String adminEmail = AuthRemoteDataSourceImpl.authorizedAdminEmail;

  StreamSubscription<bool>? _sessionSubscription;

  AuthBloc({
    required this.sendSignInLink,
    required this.watchSessionApproval,
    required this.completeSessionLogin,
    required this.checkAuthStatus,
    required this.signOut,
  }) : super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheck);
    on<AuthSendLinkRequested>(_onSendLink);
    on<AuthSessionApprovedEvent>(_onSessionApproved);
    on<AuthSignOutRequested>(_onSignOut);
  }

  @override
  Future<void> close() {
    _sessionSubscription?.cancel();
    return super.close();
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
          emit(const Authenticated());
        } else {
          emit(const Unauthenticated());
        }
      },
    );
  }

  Future<void> _onSendLink(
    AuthSendLinkRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await sendSignInLink();
    result.fold(
      (failure) => emit(AuthFailureState(failure.message)),
      (sessionId) {
        _sessionSubscription?.cancel();
        _sessionSubscription =
            watchSessionApproval(sessionId).listen((isApproved) {
          if (isApproved) {
            add(AuthSessionApprovedEvent(sessionId: sessionId));
          }
        });

        emit(AuthLinkSentState(sessionId: sessionId));
      },
    );
  }

  Future<void> _onSessionApproved(
    AuthSessionApprovedEvent event,
    Emitter<AuthState> emit,
  ) async {
    _sessionSubscription?.cancel();
    emit(const AuthLoading(message: 'Logging in...'));
    final result = await completeSessionLogin(event.sessionId);
    result.fold(
      (failure) => emit(AuthFailureState(failure.message)),
      (_) => emit(const Authenticated()),
    );
  }

  Future<void> _onSignOut(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    _sessionSubscription?.cancel();
    await signOut();
    emit(const Unauthenticated());
  }
}
