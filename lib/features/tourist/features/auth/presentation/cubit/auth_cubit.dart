import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/check_email_usecas.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/verify_password_usecase.dart';
import '../../domain/usecases/google_login_usecase.dart';
import '../../domain/usecases/forgot_password_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final CheckEmailUseCase checkEmailUseCase;
  final VerifyPasswordUseCase verifyPasswordUseCase;
  final RegisterUseCase registerUseCase;
  final GoogleLoginUseCase googleLoginUseCase;
  final ForgotPasswordUseCase forgotPasswordUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;
  final AuthRepository authRepository;

  AuthCubit({
    required this.checkEmailUseCase,
    required this.verifyPasswordUseCase,
    required this.registerUseCase,
    required this.googleLoginUseCase,
    required this.forgotPasswordUseCase,
    required this.resetPasswordUseCase,
    required this.authRepository,
  }) : super(AuthInitial());

  /// Check for cached user on app start
  Future<void> checkAuthStatus() async {
    emit(AuthLoading());

    final result = await authRepository.getCachedUser();

    result.fold(
          (failure) => emit(AuthUnauthenticated()),
          (user) {
        if (user != null) {
          emit(AuthAuthenticated(user));
        } else {
          emit(AuthUnauthenticated());
        }
      },
    );
  }

  // ---------------- CHECK EMAIL ----------------
  Future<void> checkEmail(String email) async {
    emit(AuthLoading());

    final result = await checkEmailUseCase(email);

    result.fold(
          (failure) => emit(AuthError(failure.message)),
          (data) {
        if (data['action'] == 'go_to_password_page') {
          emit(AuthEmailExists(email));
        } else if (data['action'] == 'go_to_register_page') {
          emit(AuthError('Email not found. Please register first.'));
        } else {
          emit(AuthError(data['message'] ?? 'Unknown error occurred'));
        }
      },
    );
  }

  // ---------------- VERIFY PASSWORD ----------------
  Future<void> verifyPassword(String email, String password) async {
    emit(AuthLoading());

    final result = await verifyPasswordUseCase(email, password);

    result.fold(
          (failure) => emit(AuthError(failure.message)),
          (user) => emit(AuthAuthenticated(user)),
    );
  }

  // ---------------- REGISTER ----------------
  Future<void> register({
    required String email,
    required String userName,
    required String password,
    required String phoneNumber,
    required String gender,
    required DateTime birthDate,
    required String country,
  }) async {
    emit(AuthLoading());

    final result = await registerUseCase(
      email: email,
      userName: userName,
      password: password,
      phoneNumber: phoneNumber,
      gender: gender,
      birthDate: birthDate,
      country: country,
    );

    result.fold(
          (failure) => emit(AuthError(failure.message)),
          (user) => emit(AuthAuthenticated(user)),
    );
  }

  // ---------------- GOOGLE LOGIN ----------------
  Future<void> googleLogin(String email) async {
    emit(AuthLoading());

    final result = await googleLoginUseCase(email);

    result.fold(
          (failure) => emit(AuthError(failure.message)),
          (data) {
        final message = data['message'] ?? '';
        final action = data['action'] ?? '';

        if (action == 'login_success') {
          emit(AuthMessage(message, action));
        } else if (action == 'need_registration') {
          emit(AuthGoogleRegistrationNeeded(email));
        } else if (action == 'code_sent' ||
            message.contains('Verification code sent')) {
          emit(AuthGoogleVerificationNeeded(email, message));
        } else {
          emit(AuthError(message.isNotEmpty ? message : 'Google login failed'));
        }
      },
    );
  }

  // ---------------- FORGOT PASSWORD ----------------
  Future<void> forgotPassword(String email) async {
    emit(AuthLoading());

    final result = await forgotPasswordUseCase(email);

    result.fold(
          (failure) => emit(AuthError(failure.message)),
          (data) => emit(AuthForgotPasswordSent(
        message: data['message'] ?? 'Reset code sent to your email',
        email: email,
      )),
    );
  }

  // ---------------- RESET PASSWORD ----------------
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    emit(AuthLoading());

    final result = await resetPasswordUseCase(
      email: email,
      code: code,
      newPassword: newPassword,
    );

    result.fold(
          (failure) => emit(AuthError(failure.message)),
          (data) => emit(AuthPasswordResetSuccess(
        data['message'] ?? 'Password reset successfully',
      )),
    );
  }

  // ---------------- LOGOUT ----------------
  Future<void> logout() async {
    emit(AuthLoading());

    final result = await authRepository.logout();

    result.fold(
          (failure) => emit(AuthError(failure.message)),
          (_) => emit(AuthUnauthenticated()),
    );
  }

  // ---------------- RESET STATE ----------------
  void resetState() {
    emit(AuthInitial());
  }
}