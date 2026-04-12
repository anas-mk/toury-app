import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../core/errors/failures.dart';
import '../entities/helper_profile_entity.dart';
import '../repositories/profile_repository.dart';

class UpdateBasicInfoUseCase {
  final ProfileRepository repository;
  UpdateBasicInfoUseCase(this.repository);

  Future<Either<Failure, HelperProfileEntity>> call(
    UpdateBasicInfoParams params, {
    CancelToken? cancelToken,
  }) {
    return repository.updateBasicInfo(
      fullName: params.fullName,
      phoneNumber: params.phoneNumber,
      gender: params.gender,
      birthDate: params.birthDate,
      cancelToken: cancelToken,
    );
  }
}

class UpdateBasicInfoParams extends Equatable {
  final String fullName;
  final String phoneNumber;
  final String gender;
  final DateTime birthDate;

  const UpdateBasicInfoParams({
    required this.fullName,
    required this.phoneNumber,
    required this.gender,
    required this.birthDate,
  });

  @override
  List<Object?> get props => [fullName, phoneNumber, gender, birthDate];
}
