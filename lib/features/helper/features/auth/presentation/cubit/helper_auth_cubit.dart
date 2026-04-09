import 'package:flutter_bloc/flutter_bloc.dart';
import 'helper_auth_state.dart';

class HelperAuthCubit extends Cubit<HelperAuthState> {
  HelperRegistrationData _registrationData = const HelperRegistrationData();

  HelperAuthCubit() : super(HelperAuthInitial());

  void initRegistrationData() {
    _registrationData = const HelperRegistrationData();
    emit(HelperAuthRegisterProgress(_registrationData));
  }

  void updateRegistrationData(HelperRegistrationData updatedData) {
    _registrationData = updatedData;
    emit(HelperAuthRegisterProgress(_registrationData));
  }

  // ---------------- CHECK EMAIL ----------------
  Future<void> checkEmail(String email) async {
    emit(HelperAuthLoading());
    await Future.delayed(const Duration(seconds: 1)); // Mocking API
    emit(HelperAuthEmailExists(email));
  }

  // ---------------- VERIFY PASSWORD ----------------
  Future<void> verifyPassword(String email, String password) async {
    emit(HelperAuthLoading());
    await Future.delayed(const Duration(seconds: 1)); // Mocking API
    emit(const HelperAuthAuthenticated());
  }

  // ---------------- REGISTER HELPER ----------------
  Future<void> registerHelper() async {
    emit(HelperAuthLoading());
    await Future.delayed(const Duration(seconds: 1)); // Mocking API

    emit(HelperAuthRegistrationVerificationNeeded(
      email: _registrationData.email.isNotEmpty ? _registrationData.email : 'mock@example.com',
      message: 'Please verify your email',
    ));
  }

  // ---------------- VERIFY REGISTRATION CODE ----------------
  Future<void> verifyRegistrationCode({
    required String email,
    required String code,
  }) async {
    emit(HelperAuthLoading());
    await Future.delayed(const Duration(seconds: 1)); // Mocking API
    
    emit(const HelperAuthVerificationSuccess(
      token: 'mock_token',
      message: 'Verification successful',
    ));
  }

  // ---------------- RESEND VERIFICATION CODE ----------------
  Future<void> resendVerificationCode(String email) async {
    emit(HelperAuthLoading());
    await Future.delayed(const Duration(seconds: 1)); // Mocking API
    emit(const HelperAuthResendCodeSuccess('Code sent successfully'));
  }

  // ---------------- GOOGLE LOGIN ----------------
  Future<void> googleLogin(String email) async {
    emit(HelperAuthLoading());
    await Future.delayed(const Duration(seconds: 1)); // Mocking API
    emit(HelperAuthGoogleRegistrationNeeded(email));
  }

  // ---------------- FORGOT PASSWORD ----------------
  Future<void> forgotPassword(String email) async {
    emit(HelperAuthLoading());
    await Future.delayed(const Duration(seconds: 1)); // Mocking API
    emit(HelperAuthForgotPasswordSent(
      message: 'Reset code sent to your email',
      email: email,
    ));
  }

  // ---------------- RESET PASSWORD ----------------
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    emit(HelperAuthLoading());
    await Future.delayed(const Duration(seconds: 1)); // Mocking API
    emit(const HelperAuthPasswordResetSuccess('Password reset successfully'));
  }

  // ---------------- LOGOUT ----------------
  Future<void> logout() async {
    emit(HelperAuthLoading());
    await Future.delayed(const Duration(seconds: 1)); // Mocking API
    emit(HelperAuthUnauthenticated());
  }

  // ---------------- RESET STATE ----------------
  void resetState() {
    emit(HelperAuthInitial());
  }
}
