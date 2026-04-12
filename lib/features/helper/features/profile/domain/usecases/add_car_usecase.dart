import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../core/errors/failures.dart';
import '../entities/car_entity.dart';
import '../repositories/profile_repository.dart';

class AddCarUseCase {
  final ProfileRepository repository;
  AddCarUseCase(this.repository);

  Future<Either<Failure, CarEntity>> call(
    AddCarParams params, {
    CancelToken? cancelToken,
  }) {
    return repository.addOrUpdateCar(
      brand: params.brand,
      model: params.model,
      color: params.color,
      licensePlate: params.licensePlate,
      energyType: params.energyType,
      carType: params.carType,
      carLicenseFront: params.carLicenseFront,
      carLicenseBack: params.carLicenseBack,
      cancelToken: cancelToken,
    );
  }
}

class AddCarParams extends Equatable {
  final String brand;
  final String model;
  final String color;
  final String licensePlate;
  final String energyType;
  final String carType;
  final File? carLicenseFront;
  final File? carLicenseBack;

  const AddCarParams({
    required this.brand,
    required this.model,
    required this.color,
    required this.licensePlate,
    required this.energyType,
    required this.carType,
    this.carLicenseFront,
    this.carLicenseBack,
  });

  @override
  List<Object?> get props => [
        brand,
        model,
        color,
        licensePlate,
        energyType,
        carType,
        carLicenseFront,
        carLicenseBack,
      ];
}
