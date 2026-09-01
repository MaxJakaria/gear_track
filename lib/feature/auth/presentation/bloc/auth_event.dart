part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

final class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

final class AuthSendLinkRequested extends AuthEvent {
  const AuthSendLinkRequested();
}

final class AuthSessionApprovedEvent extends AuthEvent {
  final String sessionId;
  const AuthSessionApprovedEvent({required this.sessionId});
  @override
  List<Object?> get props => [sessionId];
}

final class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}
