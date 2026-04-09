import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

class HelperRegistrationData extends Equatable {
  final int currentStep;
  final String fullName;
  final String email;
  final String password;
  final String phoneNumber;
  final String gender;
  final DateTime? birthDate;

  final XFile? selfieImage;
  final XFile? nationalIdFront;
  final XFile? nationalIdBack;

  final XFile? criminalRecordFile;
  final XFile? drugTestFile;

  final XFile? carLicenseFront;
  final XFile? carLicenseBack;
  final XFile? personalLicense;

  const HelperRegistrationData({
    this.currentStep = 0,
    this.fullName = '',
    this.email = '',
    this.password = '',
    this.phoneNumber = '',
    this.gender = 'Male',
    this.birthDate,
    this.selfieImage,
    this.nationalIdFront,
    this.nationalIdBack,
    this.criminalRecordFile,
    this.drugTestFile,
    this.carLicenseFront,
    this.carLicenseBack,
    this.personalLicense,
  });

  HelperRegistrationData copyWith({
    int? currentStep,
    String? fullName,
    String? email,
    String? password,
    String? phoneNumber,
    String? gender,
    DateTime? birthDate,
    XFile? selfieImage,
    XFile? nationalIdFront,
    XFile? nationalIdBack,
    XFile? criminalRecordFile,
    XFile? drugTestFile,
    XFile? carLicenseFront,
    XFile? carLicenseBack,
    XFile? personalLicense,
  }) {
    return HelperRegistrationData(
      currentStep: currentStep ?? this.currentStep,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      password: password ?? this.password,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      selfieImage: selfieImage ?? this.selfieImage,
      nationalIdFront: nationalIdFront ?? this.nationalIdFront,
      nationalIdBack: nationalIdBack ?? this.nationalIdBack,
      criminalRecordFile: criminalRecordFile ?? this.criminalRecordFile,
      drugTestFile: drugTestFile ?? this.drugTestFile,
      carLicenseFront: carLicenseFront ?? this.carLicenseFront,
      carLicenseBack: carLicenseBack ?? this.carLicenseBack,
      personalLicense: personalLicense ?? this.personalLicense,
    );
  }

  @override
  List<Object?> get props => [
        currentStep, fullName, email, password, phoneNumber, gender, birthDate,
        selfieImage?.path, nationalIdFront?.path, nationalIdBack?.path,
        criminalRecordFile?.path, drugTestFile?.path,
        carLicenseFront?.path, carLicenseBack?.path, personalLicense?.path,
      ];
}

abstract class HelperAuthState extends Equatable {
  const HelperAuthState();

  @override
  List<Object?> get props => [];
}

class HelperAuthInitial extends HelperAuthState {}

class HelperAuthRegisterProgress extends HelperAuthState {
  final HelperRegistrationData data;
  const HelperAuthRegisterProgress(this.data);

  @override
  List<Object?> get props => [data];
}

class HelperAuthLoading extends HelperAuthState {}

class HelperAuthEmailExists extends HelperAuthState {
  final String email;
  const HelperAuthEmailExists(this.email);

  @override
  List<Object?> get props => [email];
}

class HelperAuthAuthenticated extends HelperAuthState {
  const HelperAuthAuthenticated();
}

class HelperAuthUnauthenticated extends HelperAuthState {}

class HelperAuthError extends HelperAuthState {
  final String message;
  const HelperAuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class HelperAuthGoogleRegistrationNeeded extends HelperAuthState {
  final String email;
  const HelperAuthGoogleRegistrationNeeded(this.email);

  @override
  List<Object?> get props => [email];
}

class HelperAuthGoogleVerificationNeeded extends HelperAuthState {
  final String email;
  final String message;
  const HelperAuthGoogleVerificationNeeded(this.email, this.message);

  @override
  List<Object?> get props => [email, message];
}

class HelperAuthMessage extends HelperAuthState {
  final String message;
  final String action;

  const HelperAuthMessage(this.message, this.action);

  @override
  List<Object?> get props => [message, action];
}

// Forgot Password States
class HelperAuthForgotPasswordSent extends HelperAuthState {
  final String message;
  final String email;

  const HelperAuthForgotPasswordSent({
    required this.message,
    required this.email,
  });

  @override
  List<Object?> get props => [message, email];
}

// Reset Password States
class HelperAuthPasswordResetSuccess extends HelperAuthState {
  final String message;

  const HelperAuthPasswordResetSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class HelperAuthRegistrationVerificationNeeded extends HelperAuthState {
  final String email;
  final String message;

  const HelperAuthRegistrationVerificationNeeded({
    required this.email,
    required this.message,
  });

  @override
  List<Object?> get props => [email, message];
}

class HelperAuthVerificationSuccess extends HelperAuthState {
  final String token;
  final String message;

  const HelperAuthVerificationSuccess({
    required this.token,
    required this.message,
  });

  @override
  List<Object?> get props => [token, message];
}

class HelperAuthResendCodeSuccess extends HelperAuthState {
  final String message;

  const HelperAuthResendCodeSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
