part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthLoading extends AuthState {
  final String message;

  const AuthLoading({this.message = 'Please wait...'});

  @override
  List<Object?> get props => [message];
}

final class Authenticated extends AuthState {
  final User? user;

  const Authenticated({this.user});

  @override
  List<Object?> get props => [user];
}

final class Unauthenticated extends AuthState {
  const Unauthenticated();
}

final class AuthFailureState extends AuthState {
  final String message;
  final int timestamp;

  AuthFailureState(this.message)
      : timestamp = DateTime.now().microsecondsSinceEpoch;

  @override
  List<Object?> get props => [message, timestamp];
}

final class AuthPasswordResetSentState extends AuthState {
  final String email;
  final int timestamp;

  AuthPasswordResetSentState({required this.email})
      : timestamp = DateTime.now().microsecondsSinceEpoch;

  @override
  List<Object?> get props => [email, timestamp];
}
