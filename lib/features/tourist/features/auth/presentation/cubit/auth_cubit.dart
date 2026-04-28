import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/services/auth_service.dart';
import '../../../../../../core/services/notifications/messaging_service.dart';
import '../../../../../../core/services/signalr/booking_tracking_hub_service.dart';
import '../../domain/usecases/check_email_usecas.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/resend_verification_code_usecase.dart';
import '../../domain/usecases/verify_password_usecase.dart';
import '../../domain/usecases/google_login_usecase.dart';
import '../../domain/usecases/forgot_password_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';
import '../../domain/usecases/verify_code_usecase.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final CheckEmailUseCase checkEmailUseCase;
  final VerifyPasswordUseCase verifyPasswordUseCase;
  final RegisterUseCase registerUseCase;
  final GoogleLoginUseCase googleLoginUseCase;
  final ForgotPasswordUseCase forgotPasswordUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;
  final VerifyCodeUseCase verifyCodeUseCase;
  final AuthRepository authRepository;

  final ResendVerificationCodeUseCase resendVerificationCodeUseCase;
  final AuthService authService;
  final BookingTrackingHubService hubService;
  final MessagingService messagingService;

  AuthCubit({
    required this.checkEmailUseCase,
    required this.verifyPasswordUseCase,
    required this.registerUseCase,
    required this.googleLoginUseCase,
    required this.forgotPasswordUseCase,
    required this.resetPasswordUseCase,
    required this.verifyCodeUseCase,
    required this.resendVerificationCodeUseCase,
    required this.authRepository,
    required this.authService,
    required this.hubService,
    required this.messagingService,
  }) : super(AuthInitial());

  /// Side effects that run every time the user becomes authenticated:
  ///   1. Open the SignalR `/hubs/booking` connection (token is resolved
  ///      fresh from [AuthService] on every reconnect via the factory).
  ///   2. Start FCM (permissions, token register, foreground heads-up,
  ///      tap-routing).
  ///
  /// Both calls are best-effort — if FCM is unavailable (desktop, no
  /// google-services config, …) we still want SignalR up and the rest of
  /// the app to work.
  Future<void> _onAuthenticated() async {
    final token = authService.getToken();
    if (token == null || token.isEmpty) {
      debugPrint('⚠️ AuthCubit: no token after auth — skipping side-effects');
      return;
    }
    try {
      await hubService.start();
    } catch (e) {
      debugPrint('⚠️ AuthCubit: SignalR start failed: $e');
    }
    try {
      await messagingService.start();
    } catch (e) {
      debugPrint('⚠️ AuthCubit: MessagingService.start failed: $e');
    }
  }

  /// Mirror of [_onAuthenticated] for logout. ORDER MATTERS — the device-
  /// token unregister call needs the bearer to authenticate, so it MUST run
  /// before the JWT is cleared.
  Future<void> _onUnauthenticated() async {
    try {
      await messagingService.stop();
    } catch (e) {
      debugPrint('⚠️ AuthCubit: MessagingService.stop failed: $e');
    }
    try {
      await hubService.stop();
    } catch (e) {
      debugPrint('⚠️ AuthCubit: SignalR stop failed: $e');
    }
  }

  /// Check for cached user on app start
  Future<void> checkAuthStatus() async {
    emit(AuthLoading());

    final result = await authRepository.getCachedUser();

    await result.fold(
          (failure) async => emit(AuthUnauthenticated()),
          (user) async {
        if (user != null) {
          emit(AuthAuthenticated(user));
          await _onAuthenticated();
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

    await result.fold(
          (failure) async => emit(AuthError(failure.message)),
          (user) async {
        emit(AuthAuthenticated(user));
        await _onAuthenticated();
      },
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

    await result.fold(
          (failure) async {
        final errorMessage = failure.message
            .replaceAll('Exception: ', '')
            .replaceAll('exception: ', '');

        debugPrint('🔍 Cubit received failure: $errorMessage');

        if (errorMessage.contains('VERIFICATION_NEEDED:')) {
          final parts = errorMessage.split(':');
          final emailFromError = parts.length > 1 ? parts[1] : email;
          final message = parts.length > 2 ? parts.sublist(2).join(':') : 'Please verify your email';

          emit(AuthRegistrationVerificationNeeded(
            email: emailFromError,
            message: message,
          ));
        } else {
          emit(AuthError(errorMessage));
        }
      },
          (user) async {
        debugPrint('✅ Registration successful');
        emit(AuthAuthenticated(user));
        await _onAuthenticated();
      },
    );
  }

  // ---------------- VERIFY REGISTRATION CODE ----------------
  Future<void> verifyRegistrationCode({
    required String email,
    required String code,
  }) async {
    emit(AuthLoading());

    final result = await verifyCodeUseCase(
      email: email,
      code: code,
    );

    result.fold(
          (failure) => emit(AuthError(failure.message)),
          (data) {
        // ✅ After successful verification, navigate to login or get user domain
        final token = data['token'];
        final message = data['message'] ?? 'Verification successful';

        emit(AuthVerificationSuccess(
          token: token,
          message: message,
        ));
      },
    );
  }

  // ---------------- RESEND VERIFICATION CODE ----------------
  Future<void> resendVerificationCode(String email) async {
    final result = await resendVerificationCodeUseCase(email);

    result.fold(
          (failure) => emit(AuthError(failure.message)),
          (data) {
        // Don't change state, just show success via listener
        emit(AuthResendCodeSuccess(data['message'] ?? 'Code sent successfully'));
      },
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

    // Best-effort side-effects BEFORE we drop the token: the device-token
    // unregister call needs the bearer to authenticate.
    await _onUnauthenticated();

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
