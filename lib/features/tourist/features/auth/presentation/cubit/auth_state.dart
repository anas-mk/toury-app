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

class AuthGoogleRegistrationNeeded extends AuthState {
  final String email;
  const AuthGoogleRegistrationNeeded(this.email);

  @override
  List<Object?> get props => [email];
}

class AuthGoogleVerificationNeeded extends AuthState {
  final String email;
  final String message;
  const AuthGoogleVerificationNeeded(this.email, this.message);

  @override
  List<Object?> get props => [email, message];
}

class AuthMessage extends AuthState {
  final String message;
  final String action;

  const AuthMessage(this.message, this.action);

  @override
  List<Object?> get props => [message, action];
}

// Forgot Password States
class AuthForgotPasswordSent extends AuthState {
  final String message;
  final String email;

  const AuthForgotPasswordSent({
    required this.message,
    required this.email,
  });

  @override
  List<Object?> get props => [message, email];
}

// Reset Password States
class AuthPasswordResetSuccess extends AuthState {
  final String message;

  const AuthPasswordResetSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

// Registration Verification Needed State
class AuthRegistrationVerificationNeeded extends AuthState {
  final String email;
  final String message;

  const AuthRegistrationVerificationNeeded({
    required this.email,
    required this.message,
  });

  @override
  List<Object?> get props => [email, message];
}

//Verification Success State (before getting full user domain)
class AuthVerificationSuccess extends AuthState {
  final String token;
  final String message;

  const AuthVerificationSuccess({
    required this.token,
    required this.message,
  });

  @override
  List<Object?> get props => [token, message];
}



class AuthResendCodeSuccess extends AuthState {
  final String message;

  const AuthResendCodeSuccess(this.message);

  @override
  List<Object?> get props => [message];
}