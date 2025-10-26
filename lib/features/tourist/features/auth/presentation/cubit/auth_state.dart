import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthEmailExists extends AuthState {
  final String email;
  const AuthEmailExists(this.email);

  @override
  List<Object?> get props => [email];
}

class AuthAuthenticated extends AuthState {
  final UserEntity user;
  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthPasswordError extends AuthState {
  final String message;
  const AuthPasswordError(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthPasswordUpdated extends AuthState {
  const AuthPasswordUpdated();
}

class AuthPasswordResetSent extends AuthState {
  final String message;
  const AuthPasswordResetSent(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthGoogleRegistrationNeeded extends AuthState {
  final String email;
  const AuthGoogleRegistrationNeeded(this.email);

  @override
  List<Object?> get props => [email];
}

class AuthSuccess extends AuthState {
  final String message;
  const AuthSuccess(this.message);
}

class AuthGoogleVerificationNeeded extends AuthState {
  final String email;
  final String message;
  const AuthGoogleVerificationNeeded(this.email, this.message);

  @override
  List<Object?> get props => [email, message];
}

class AuthGoogleSuccess extends AuthState {
  final String message;
  const AuthGoogleSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthMessage extends AuthState {
  final String message;
  final String action;

  AuthMessage(this.message, this.action);
}
