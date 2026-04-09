import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../repositories/helper_auth_repository.dart';
import '../../data/models/helper_auth_response_model.dart';

class HelperRegisterParams {
  final String fullName;
  final String email;
  final String password;
  final String phoneNumber;
  final String gender;
  final DateTime? birthDate;

  final String? profileImagePath;
  final String? selfieImagePath;
  final String? nationalIdFrontPath;
  final String? nationalIdBackPath;
  final String? criminalRecordFilePath;
  final String? drugTestFilePath;

  final bool hasCar;
  final String? carBrand;
  final String? carModel;
  final String? carColor;
  final String? carLicensePlate;
  final String? carEnergyType;
  final String? carType;

  final String? carLicenseFrontPath;
  final String? carLicenseBackPath;
  final String? personalLicensePath;

  HelperRegisterParams({
    required this.fullName,
    required this.email,
    required this.password,
    required this.phoneNumber,
    required this.gender,
    this.birthDate,
    this.profileImagePath,
    this.selfieImagePath,
    this.nationalIdFrontPath,
    this.nationalIdBackPath,
    this.criminalRecordFilePath,
    this.drugTestFilePath,
    this.hasCar = false,
    this.carBrand,
    this.carModel,
    this.carColor,
    this.carLicensePlate,
    this.carEnergyType,
    this.carType,
    this.carLicenseFrontPath,
    this.carLicenseBackPath,
    this.personalLicensePath,
  });
}

class RegisterHelperUseCase {
  final HelperAuthRepository repository;

  RegisterHelperUseCase(this.repository);

  Future<Either<Failure, HelperAuthResponseModel>> call(HelperRegisterParams params) async {
    return await repository.registerHelper(params);
  }
}
