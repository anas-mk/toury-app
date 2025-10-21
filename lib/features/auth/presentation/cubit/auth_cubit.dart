import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/check_email_usecas.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/verify_password_usecase.dart';
import '../../domain/usecases/forgot_password_usecase.dart';
import '../../domain/usecases/google_login_usecase.dart';
import '../../domain/usecases/google_register_usecase.dart';
import '../../domain/usecases/verify_google_token_usecase.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final CheckEmailUseCase checkEmailUseCase;
  final VerifyPasswordUseCase verifyPasswordUseCase;
  final RegisterUseCase registerUseCase;
  final ForgotPasswordUseCase forgotPasswordUseCase;
  final GoogleLoginUseCase googleLoginUseCase;
  final GoogleRegisterUseCase googleRegisterUseCase;
  final VerifyGoogleTokenUseCase verifyGoogleTokenUseCase;
  final AuthRepository authRepository;

  AuthCubit({
    required this.checkEmailUseCase,
    required this.verifyPasswordUseCase,
    required this.registerUseCase,
    required this.forgotPasswordUseCase,
    required this.googleLoginUseCase,
    required this.googleRegisterUseCase,
    required this.verifyGoogleTokenUseCase,
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

  // ---------------- FORGOT PASSWORD ----------------
  Future<void> forgotPassword(String email) async {
    emit(AuthLoading());

    final result = await forgotPasswordUseCase(email);

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (message) => emit(AuthPasswordResetSent(message)),
    );
  }

  // ---------------- GET CURRENT USER ----------------
  Future<void> getCurrentUser() async {
    emit(AuthLoading());

    final result = await authRepository.getCurrentUser();

    result.fold((failure) => emit(AuthError(failure.message)), (user) {
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    });
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

  // ---------------- GOOGLE LOGIN ----------------
  Future<void> googleLogin(String googleToken) async {
    emit(AuthLoading());

    final result = await googleLoginUseCase(googleToken);

    result.fold((failure) => emit(AuthError(failure.message)), (data) {
      if (data['action'] == 'login_success') {
        // User exists, authenticate directly
        final userData = data['user'];
        if (userData != null) {
          final user = UserEntity(
            id: userData['id'] ?? '',
            email: userData['email'] ?? '',
            userName: userData['userName'] ?? '',
            phoneNumber: userData['phoneNumber'] ?? '',
            gender: userData['gender'] ?? '',
            birthDate: userData['birthDate'] != null
                ? DateTime.tryParse(userData['birthDate'])
                : null,
            country: userData['country'] ?? '',
          );
          emit(AuthAuthenticated(user));
        }
      } else if (data['action'] == 'need_registration') {
        // User doesn't exist, need to register
        emit(AuthGoogleRegistrationNeeded(googleToken));
      } else {
        emit(AuthError(data['message'] ?? 'Google login failed'));
      }
    });
  }

  // ---------------- GOOGLE REGISTER ----------------
  Future<void> googleRegister({
    required String googleId,
    required String name,
    required String email,
  }) async {
    emit(AuthLoading());

    final result = await googleRegisterUseCase(
      googleId: googleId,
      name: name,
      email: email,
    );

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user as UserEntity)),
    );
  }

  // ---------------- VERIFY GOOGLE TOKEN ----------------
  Future<void> verifyGoogleToken(String googleToken) async {
    emit(AuthLoading());

    final result = await verifyGoogleTokenUseCase(googleToken);

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  // ---------------- SAVE USER DATA ----------------
  Future<void> _saveUserData(UserEntity user, String? token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString('auth_token', token);
    }
    await prefs.setString('user_data', user.toJson().toString());
  }
}
