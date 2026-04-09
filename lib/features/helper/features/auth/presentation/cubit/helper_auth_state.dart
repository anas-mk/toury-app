import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/helper_entity.dart';

class HelperRegistrationData extends Equatable {
  final int currentStep;
  final String fullName;
  final String email;
  final String password;
  final String phoneNumber;
  final String gender;
  final DateTime? birthDate;

  final XFile? profileImage;
  final XFile? selfieImage;
  final XFile? nationalIdFront;
  final XFile? nationalIdBack;

  final XFile? criminalRecordFile;
  final XFile? drugTestFile;

  final bool hasCar;
  final String carBrand;
  final String carModel;
  final String carColor;
  final String carLicensePlate;
  final String carEnergyType;
  final String carType;

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
    this.profileImage,
    this.selfieImage,
    this.nationalIdFront,
    this.nationalIdBack,
    this.criminalRecordFile,
    this.drugTestFile,
    this.hasCar = false,
    this.carBrand = '',
    this.carModel = '',
    this.carColor = '',
    this.carLicensePlate = '',
    this.carEnergyType = '',
    this.carType = '',
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
    XFile? profileImage,
    XFile? selfieImage,
    XFile? nationalIdFront,
    XFile? nationalIdBack,
    XFile? criminalRecordFile,
    XFile? drugTestFile,
    bool? hasCar,
    String? carBrand,
    String? carModel,
    String? carColor,
    String? carLicensePlate,
    String? carEnergyType,
    String? carType,
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
      profileImage: profileImage ?? this.profileImage,
      selfieImage: selfieImage ?? this.selfieImage,
      nationalIdFront: nationalIdFront ?? this.nationalIdFront,
      nationalIdBack: nationalIdBack ?? this.nationalIdBack,
      criminalRecordFile: criminalRecordFile ?? this.criminalRecordFile,
      drugTestFile: drugTestFile ?? this.drugTestFile,
      hasCar: hasCar ?? this.hasCar,
      carBrand: carBrand ?? this.carBrand,
      carModel: carModel ?? this.carModel,
      carColor: carColor ?? this.carColor,
      carLicensePlate: carLicensePlate ?? this.carLicensePlate,
      carEnergyType: carEnergyType ?? this.carEnergyType,
      carType: carType ?? this.carType,
      carLicenseFront: carLicenseFront ?? this.carLicenseFront,
      carLicenseBack: carLicenseBack ?? this.carLicenseBack,
      personalLicense: personalLicense ?? this.personalLicense,
    );
  }

  @override
  List<Object?> get props => [
        currentStep, fullName, email, password, phoneNumber, gender, birthDate,
        profileImage?.path, selfieImage?.path, nationalIdFront?.path, nationalIdBack?.path,
        criminalRecordFile?.path, drugTestFile?.path,
        hasCar, carBrand, carModel, carColor, carLicensePlate, carEnergyType, carType,
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

class HelperAuthAuthenticated extends HelperAuthState {
  final HelperEntity helper;
  const HelperAuthAuthenticated(this.helper);

  @override
  List<Object?> get props => [helper];
}

class HelperAuthUnauthenticated extends HelperAuthState {}

class HelperAuthError extends HelperAuthState {
  final String message;
  const HelperAuthError(this.message);

  @override
  List<Object?> get props => [message];
}

// Login States
class HelperAuthLoginOtpRequired extends HelperAuthState {
  final String email;
  final String message;

  const HelperAuthLoginOtpRequired({
    required this.email,
    required this.message,
  });

  @override
  List<Object?> get props => [email, message];
}

// Registration States
class HelperAuthEmailVerificationRequired extends HelperAuthState {
  final String email;
  final String message;

  const HelperAuthEmailVerificationRequired({
    required this.email,
    required this.message,
  });

  @override
  List<Object?> get props => [email, message];
}

class HelperAuthRegistrationSuccess extends HelperAuthState {
  final String message;
  final HelperEntity? helper; // Optional auto-login info
  final String? action;

  const HelperAuthRegistrationSuccess({
    required this.message,
    this.helper,
    this.action,
  });

  @override
  List<Object?> get props => [message, helper, action];
}

// Forgot/Reset Password
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

class HelperAuthPasswordResetSuccess extends HelperAuthState {
  final String message;
  const HelperAuthPasswordResetSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

// Success Signals
class HelperAuthResendSuccess extends HelperAuthState {
  final String message;
  const HelperAuthResendSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
