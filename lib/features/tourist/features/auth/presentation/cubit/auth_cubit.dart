import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/check_email_usecas.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/verify_google_code_usecase.dart';
import '../../domain/usecases/verify_password_usecase.dart';
import '../../domain/usecases/google_login_usecase.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final CheckEmailUseCase checkEmailUseCase;
  final VerifyPasswordUseCase verifyPasswordUseCase;
  final RegisterUseCase registerUseCase;
  final GoogleLoginUseCase googleLoginUseCase;
  final VerifyGoogleCodeUseCase verifyGoogleCodeUseCase;
  final AuthRepository authRepository;

  AuthCubit({
    required this.checkEmailUseCase,
    required this.verifyPasswordUseCase,
    required this.registerUseCase,
    required this.googleLoginUseCase,
    required this.verifyGoogleCodeUseCase,
    required this.authRepository,
  }) : super(AuthInitial());

  // ---------------- CHECK EMAIL ----------------
  Future<void> checkEmail(String email) async {
    emit(AuthLoading());

    final result = await checkEmailUseCase(email);

    result.fold((failure) => emit(AuthError(failure.message)), (data) {
      if (data['action'] == 'go_to_password_page') {
        emit(AuthEmailExists(email));
      } else if (data['action'] == 'go_to_register_page') {
        emit(AuthError('Email not found. Please register first.'));
      } else {
        emit(AuthError(data['message'] ?? 'Unknown error occurred'));
      }
    });
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

    result.fold((failure) => emit(AuthError(failure.message)), (data) {
      final message = data['message'] ?? '';

      if (data['action'] == 'login_success') {
        // Success login
      } else if (data['action'] == 'need_registration') {
        emit(AuthGoogleRegistrationNeeded(email));
      } else if (data['action'] == 'code_sent' ||
          message.contains('Verification code sent')) {
        emit(AuthGoogleVerificationNeeded(
          email,
          message,
        ));
      } else {
        emit(AuthError(message.isNotEmpty ? message : 'Google registration failed'));
      }
    });
  }

  Future<void> verifyGoogleCode({
    required String email,
    required String code,
  }) async {
    emit(AuthLoading());

    final result = await verifyGoogleCodeUseCase(
      email: email,
      code: code,
    );

    result.fold(
          (failure) => emit(AuthError(failure.message)),
          (user) => emit(AuthAuthenticated(user)),
    );
  }

}
