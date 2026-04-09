import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/register_helper_usecase.dart';
import '../../domain/usecases/helper_login_usecase.dart';
import '../../domain/usecases/verify_helper_login_otp_usecase.dart';
import '../../domain/usecases/verify_helper_email_usecase.dart';
import '../../domain/usecases/resend_helper_login_otp_usecase.dart';
import '../../domain/usecases/resend_helper_code_usecase.dart';
import '../../domain/usecases/forgot_helper_password_usecase.dart';
import '../../domain/usecases/reset_helper_password_usecase.dart';
import '../../domain/usecases/helper_logout_usecase.dart';
import 'helper_auth_state.dart';

class HelperAuthCubit extends Cubit<HelperAuthState> {
  final RegisterHelperUseCase registerHelperUseCase;
  final HelperLoginUseCase helperLoginUseCase;
  final VerifyHelperLoginOtpUseCase verifyHelperLoginOtpUseCase;
  final VerifyHelperEmailUseCase verifyHelperEmailUseCase;
  final ResendHelperLoginOtpUseCase resendHelperLoginOtpUseCase;
  final ResendHelperCodeUseCase resendHelperCodeUseCase;
  final ForgotHelperPasswordUseCase forgotHelperPasswordUseCase;
  final ResetHelperPasswordUseCase resetHelperPasswordUseCase;
  final HelperLogoutUseCase helperLogoutUseCase;

  HelperRegistrationData _registrationData = const HelperRegistrationData();

  HelperAuthCubit({
    required this.registerHelperUseCase,
    required this.helperLoginUseCase,
    required this.verifyHelperLoginOtpUseCase,
    required this.verifyHelperEmailUseCase,
    required this.resendHelperLoginOtpUseCase,
    required this.resendHelperCodeUseCase,
    required this.forgotHelperPasswordUseCase,
    required this.resetHelperPasswordUseCase,
    required this.helperLogoutUseCase,
  }) : super(HelperAuthInitial());

  void initRegistrationData() {
    _registrationData = const HelperRegistrationData();
    emit(HelperAuthRegisterProgress(_registrationData));
  }

  void updateRegistrationData(HelperRegistrationData updatedData) {
    _registrationData = updatedData;
    emit(HelperAuthRegisterProgress(_registrationData));
  }

  // ---------------- LOGIN ----------------
  Future<void> login({required String email, required String password}) async {
    emit(HelperAuthLoading());
    final result = await helperLoginUseCase(email: email, password: password);
    result.fold(
      (failure) => emit(HelperAuthError(failure.message)),
      (response) {
        if (response.requiresOtp && response.action == 'verify_login_otp') {
          emit(HelperAuthLoginOtpRequired(
            email: email,
            message: response.message,
          ));
        } else if (response.action == 'go_to_helper_dashboard') {
          // This case assumes login might not require OTP in some scenarios
          // but for now, we follow the verify-login-otp flow.
          emit(const HelperAuthResendSuccess('Navigation action: Dashboard (pending implementation)'));
        } else {
          emit(HelperAuthError('Unexpected action: ${response.action}'));
        }
      },
    );
  }

  // ---------------- VERIFY LOGIN OTP ----------------
  Future<void> verifyLoginOtp({required String email, required String code}) async {
    emit(HelperAuthLoading());
    final result = await verifyHelperLoginOtpUseCase(email: email, code: code);
    result.fold(
      (failure) => emit(HelperAuthError(failure.message)),
      (response) {
        if (response.data != null) {
          emit(HelperAuthAuthenticated(response.data!));
        } else {
          emit(HelperAuthError('Verification successful but no data returned'));
        }
      },
    );
  }

  // ---------------- RESEND LOGIN OTP ----------------
  Future<void> resendLoginOtp(String email) async {
    emit(HelperAuthLoading());
    final result = await resendHelperLoginOtpUseCase(email);
    result.fold(
      (failure) => emit(HelperAuthError(failure.message)),
      (unit) => emit(const HelperAuthResendSuccess('Login code resent successfully')),
    );
  }

  // ---------------- REGISTER ----------------
  Future<void> registerHelper() async {
    emit(HelperAuthLoading());
    
    final params = HelperRegisterParams(
      fullName: _registrationData.fullName,
      email: _registrationData.email,
      password: _registrationData.password,
      phoneNumber: _registrationData.phoneNumber,
      gender: _registrationData.gender,
      birthDate: _registrationData.birthDate,
      profileImagePath: _registrationData.profileImage?.path,
      selfieImagePath: _registrationData.selfieImage?.path,
      nationalIdFrontPath: _registrationData.nationalIdFront?.path,
      nationalIdBackPath: _registrationData.nationalIdBack?.path,
      criminalRecordFilePath: _registrationData.criminalRecordFile?.path,
      drugTestFilePath: _registrationData.drugTestFile?.path,
      hasCar: _registrationData.hasCar,
      carBrand: _registrationData.carBrand,
      carModel: _registrationData.carModel,
      carColor: _registrationData.carColor,
      carLicensePlate: _registrationData.carLicensePlate,
      carEnergyType: _registrationData.carEnergyType,
      carType: _registrationData.carType,
      carLicenseFrontPath: _registrationData.carLicenseFront?.path,
      carLicenseBackPath: _registrationData.carLicenseBack?.path,
      personalLicensePath: _registrationData.personalLicense?.path,
    );

    final result = await registerHelperUseCase(params);

    result.fold(
      (failure) => emit(HelperAuthError(failure.message)),
      (response) {
        if (response.action == 'verify_email') {
          emit(HelperAuthEmailVerificationRequired(
            email: _registrationData.email,
            message: response.message,
          ));
        } else if (response.action == 'start_onboarding') {
          emit(HelperAuthRegistrationSuccess(
            message: response.message,
            helper: response.data,
            action: response.action,
          ));
        } else {
          emit(HelperAuthError('Unexpected action: ${response.action}'));
        }
      },
    );
  }

  // ---------------- VERIFY EMAIL (REGISTRATION) ----------------
  Future<void> verifyEmail({required String email, required String code}) async {
    emit(HelperAuthLoading());
    final result = await verifyHelperEmailUseCase(email: email, code: code);
    result.fold(
      (failure) => emit(HelperAuthError(failure.message)),
      (response) {
        if (response.action == 'start_onboarding' || response.action == 'go_to_helper_dashboard') {
          emit(HelperAuthRegistrationSuccess(
            message: response.message,
            helper: response.data,
            action: response.action,
          ));
        } else {
          emit(HelperAuthError('Unexpected action: ${response.action}'));
        }
      },
    );
  }

  // ---------------- RESEND REGISTRATION CODE ----------------
  Future<void> resendRegistrationCode(String email) async {
    emit(HelperAuthLoading());
    final result = await resendHelperCodeUseCase(email);
    result.fold(
      (failure) => emit(HelperAuthError(failure.message)),
      (unit) => emit(const HelperAuthResendSuccess('Verification code resent successfully')),
    );
  }

  // ---------------- FORGOT/RESET PASSWORD ----------------
  Future<void> forgotPassword(String email) async {
    emit(HelperAuthLoading());
    final result = await forgotHelperPasswordUseCase(email);
    result.fold(
      (failure) => emit(HelperAuthError(failure.message)),
      (data) => emit(HelperAuthForgotPasswordSent(
        message: data['message'] ?? 'Reset code sent to your email',
        email: email,
      )),
    );
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    emit(HelperAuthLoading());
    final result = await resetHelperPasswordUseCase(ResetHelperParams(
      email: email,
      code: code,
      newPassword: newPassword,
    ));
    result.fold(
      (failure) => emit(HelperAuthError(failure.message)),
      (data) => emit(HelperAuthPasswordResetSuccess(data['message'] ?? 'Password reset successfully')),
    );
  }

  // ---------------- LOGOUT ----------------
  Future<void> logout() async {
    emit(HelperAuthLoading());
    final result = await helperLogoutUseCase();
    result.fold(
      (failure) => emit(HelperAuthError(failure.message)),
      (_) => emit(HelperAuthUnauthenticated()),
    );
  }

  void resetState() {
    emit(HelperAuthInitial());
  }
}
