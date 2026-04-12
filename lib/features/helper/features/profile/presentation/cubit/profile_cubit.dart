import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/errors/failures.dart';
import '../../../../../../core/usecase/usecase.dart';
import '../../domain/entities/helper_profile_entity.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import '../../domain/usecases/get_status_usecase.dart';
import '../../domain/usecases/add_certificate_usecase.dart';
import '../../domain/usecases/check_eligibility_usecase.dart';
import '../../domain/usecases/delete_certificate_usecase.dart';
import '../../domain/usecases/update_basic_info_usecase.dart';
import '../../domain/usecases/upload_documents_usecase.dart';
import '../../domain/usecases/upload_profile_image_usecase.dart';
import '../../domain/usecases/upload_selfie_usecase.dart';
import '../../domain/entities/helper_status_entity.dart';
import '../../domain/entities/helper_eligibility_entity.dart';
import '../../domain/usecases/add_car_usecase.dart';
import '../../domain/usecases/delete_car_usecase.dart';
import 'profile_state.dart';

/// [ProfileCubit]
///
/// Owns a central [CancelToken] that is cancelled on [close].
/// This prevents in-flight Dio requests from completing after the Cubit
/// is disposed (e.g. screen pop), which would otherwise trigger emits on
/// a closed stream and cause memory leaks.
///
/// Architecture contract:
///   - NO auth logic here — 401/403 are handled globally by [AuthInterceptor].
///   - Emits [ProfileStatus.error] with a human-readable message for the UI.
///   - Never navigates — navigation is the widget's responsibility.
class ProfileCubit extends Cubit<ProfileState> {
  final GetProfileUseCase getProfileUseCase;
  final GetStatusUseCase getStatusUseCase;
  final CheckEligibilityUseCase checkEligibilityUseCase;
  final UpdateBasicInfoUseCase updateBasicInfoUseCase;
  final UploadProfileImageUseCase uploadProfileImageUseCase;
  final UploadSelfieUseCase uploadSelfieUseCase;
  final UploadDocumentsUseCase uploadDocumentsUseCase;
  final AddCarUseCase addCarUseCase;
  final DeleteCarUseCase deleteCarUseCase;
  final AddCertificateUseCase addCertificateUseCase;
  final DeleteCertificateUseCase deleteCertificateUseCase;

  /// Central cancel token — cancelled when the cubit closes.
  CancelToken _cancelToken = CancelToken();

  ProfileCubit({
    required this.getProfileUseCase,
    required this.getStatusUseCase,
    required this.checkEligibilityUseCase,
    required this.updateBasicInfoUseCase,
    required this.uploadProfileImageUseCase,
    required this.uploadSelfieUseCase,
    required this.uploadDocumentsUseCase,
    required this.addCarUseCase,
    required this.deleteCarUseCase,
    required this.addCertificateUseCase,
    required this.deleteCertificateUseCase,
  }) : super(const ProfileState());

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  Future<void> close() {
    _cancelToken.cancel('ProfileCubit closed');
    return super.close();
  }

  /// Refreshes the token if it was previously cancelled (e.g. after close → re-open).
  void _refreshToken() {
    if (_cancelToken.isCancelled) {
      _cancelToken = CancelToken();
    }
  }

  // ── Read ────────────────────────────────────────────────────────────────────

  Future<void> fetchProfileBundle() async {
    _refreshToken();
    emit(state.copyWith(status: ProfileStatus.loading));

    try {
      // Run all 3 API calls concurrently
      final results = await Future.wait([
        getProfileUseCase(NoParams(), cancelToken: _cancelToken),
        getStatusUseCase(NoParams(), cancelToken: _cancelToken),
        checkEligibilityUseCase(NoParams(), cancelToken: _cancelToken),
      ]);

      final profileResult = results[0] as Either<Failure, HelperProfileEntity>;
      final statusResult = results[1] as Either<Failure, HelperStatusEntity>;
      final eligibilityResult = results[2] as Either<Failure, HelperEligibilityEntity>;

      String? errorMessage;

      profileResult.fold((l) => errorMessage ??= l.message, (r) => null);
      statusResult.fold((l) => errorMessage ??= l.message, (r) => null);
      eligibilityResult.fold((l) => errorMessage ??= l.message, (r) => null);

      if (errorMessage != null) {
        emit(state.copyWith(
          status: ProfileStatus.error,
          errorMessage: errorMessage,
        ));
      } else {
        // If we got here, all succeeded.
        final HelperProfileEntity profile = (profileResult as Right).value;
        final HelperStatusEntity accountStatus = (statusResult as Right).value;
        final HelperEligibilityEntity eligibility = (eligibilityResult as Right).value;

        emit(state.copyWith(
          status: ProfileStatus.loaded,
          profile: profile,
          statusRecord: accountStatus,
          eligibilityRecord: eligibility,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: ProfileStatus.error,
        errorMessage: 'An unexpected error occurred.',
      ));
    }
  }

  Future<void> loadProfile() async {
    _refreshToken();
    emit(state.copyWith(status: ProfileStatus.loading));

    final result = await getProfileUseCase(NoParams(), cancelToken: _cancelToken);
    result.fold(
      (failure) => emit(state.copyWith(
        status: ProfileStatus.error,
        errorMessage: failure.message,
      )),
      (profile) => emit(state.copyWith(
        status: ProfileStatus.loaded,
        profile: profile,
      )),
    );
  }

  Future<void> loadStatus() async {
    _refreshToken();
    final result = await getStatusUseCase(NoParams(), cancelToken: _cancelToken);
    result.fold(
      (failure) => emit(state.copyWith(
        status: ProfileStatus.error,
        errorMessage: failure.message,
      )),
      (status) => emit(state.copyWith(
        status: ProfileStatus.loaded,
        statusRecord: status,
      )),
    );
  }

  Future<void> checkEligibility() async {
    _refreshToken();
    final result = await checkEligibilityUseCase(
      NoParams(),
      cancelToken: _cancelToken,
    );
    result.fold(
      (failure) => emit(state.copyWith(
        status: ProfileStatus.error,
        errorMessage: failure.message,
      )),
      (eligible) => emit(state.copyWith(
        status: ProfileStatus.loaded,
        eligibilityRecord: eligible,
      )),
    );
  }

  // ── Update Basic Info ────────────────────────────────────────────────────────

  Future<void> updateBasicInfo({
    required String fullName,
    required String phoneNumber,
    required String gender,
    required DateTime birthDate,
  }) async {
    _refreshToken();
    emit(state.copyWith(status: ProfileStatus.updating));

    final result = await updateBasicInfoUseCase(
      UpdateBasicInfoParams(
        fullName: fullName,
        phoneNumber: phoneNumber,
        gender: gender,
        birthDate: birthDate,
      ),
      cancelToken: _cancelToken,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: ProfileStatus.error,
        errorMessage: failure.message,
      )),
      (profile) => emit(state.copyWith(
        status: ProfileStatus.success,
        profile: profile,
        successMessage: 'Profile updated successfully.',
      )),
    );
  }

  // ── Media Uploads ────────────────────────────────────────────────────────────

  Future<void> uploadProfileImage(File image) async {
    _refreshToken();
    emit(state.copyWith(status: ProfileStatus.uploadingImage));

    final result = await uploadProfileImageUseCase(
      image,
      cancelToken: _cancelToken,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: ProfileStatus.error,
        errorMessage: failure.message,
      )),
      (url) {
        // Reflect updated URL locally without a full network reload.
        final updated = state.profile;
        emit(state.copyWith(
          status: ProfileStatus.success,
          profile: updated,
          successMessage: 'Profile photo updated.',
        ));
      },
    );
  }

  Future<void> uploadSelfie(File image) async {
    _refreshToken();
    emit(state.copyWith(status: ProfileStatus.uploadingSelfie));

    final result = await uploadSelfieUseCase(image, cancelToken: _cancelToken);

    result.fold(
      (failure) => emit(state.copyWith(
        status: ProfileStatus.error,
        errorMessage: failure.message,
      )),
      (_) => emit(state.copyWith(
        status: ProfileStatus.success,
        successMessage: 'Selfie updated.',
      )),
    );
  }

  Future<void> uploadDocuments({
    required File nationalIdFront,
    required File nationalIdBack,
    File? criminalRecord,
    File? drugTest,
  }) async {
    _refreshToken();
    emit(state.copyWith(status: ProfileStatus.uploadingDocuments));

    final result = await uploadDocumentsUseCase(
      UploadDocumentsParams(
        nationalIdFront: nationalIdFront,
        nationalIdBack: nationalIdBack,
        criminalRecord: criminalRecord,
        drugTest: drugTest,
      ),
      cancelToken: _cancelToken,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: ProfileStatus.error,
        errorMessage: failure.message,
      )),
      (_) => emit(state.copyWith(
        status: ProfileStatus.success,
        successMessage: 'Documents uploaded successfully.',
      )),
    );
  }

  // ── Car ─────────────────────────────────────────────────────────────────────

  Future<void> addOrUpdateCar({
    required String brand,
    required String model,
    required String color,
    required String licensePlate,
    required String energyType,
    required String carType,
    File? carLicenseFront,
    File? carLicenseBack,
  }) async {
    _refreshToken();
    emit(state.copyWith(status: ProfileStatus.managingCar));

    final result = await addCarUseCase(
      AddCarParams(
        brand: brand,
        model: model,
        color: color,
        licensePlate: licensePlate,
        energyType: energyType,
        carType: carType,
        carLicenseFront: carLicenseFront,
        carLicenseBack: carLicenseBack,
      ),
      cancelToken: _cancelToken,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: ProfileStatus.error,
        errorMessage: failure.message,
      )),
      (_) => emit(state.copyWith(
        status: ProfileStatus.success,
        successMessage: 'Car updated successfully.',
      )),
    );
  }

  Future<void> deleteCar() async {
    _refreshToken();
    emit(state.copyWith(status: ProfileStatus.managingCar));

    final result = await deleteCarUseCase(NoParams(), cancelToken: _cancelToken);

    result.fold(
      (failure) => emit(state.copyWith(
        status: ProfileStatus.error,
        errorMessage: failure.message,
      )),
      (_) => emit(state.copyWith(
        status: ProfileStatus.success,
        successMessage: 'Car removed.',
      )),
    );
  }

  // ── Certificates ─────────────────────────────────────────────────────────────

  Future<void> addCertificate({
    required String name,
    String? issuingOrganization,
    DateTime? issueDate,
    DateTime? expiryDate,
    File? certificateFile,
  }) async {
    _refreshToken();
    emit(state.copyWith(status: ProfileStatus.managingCertificate));

    final result = await addCertificateUseCase(
      AddCertificateParams(
        name: name,
        issuingOrganization: issuingOrganization,
        issueDate: issueDate,
        expiryDate: expiryDate,
        certificateFile: certificateFile,
      ),
      cancelToken: _cancelToken,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: ProfileStatus.error,
        errorMessage: failure.message,
      )),
      (_) => emit(state.copyWith(
        status: ProfileStatus.success,
        successMessage: 'Certificate added.',
      )),
    );
  }

  Future<void> deleteCertificate(String certificateId) async {
    _refreshToken();
    emit(state.copyWith(status: ProfileStatus.managingCertificate));

    final result = await deleteCertificateUseCase(
      certificateId,
      cancelToken: _cancelToken,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: ProfileStatus.error,
        errorMessage: failure.message,
      )),
      (_) => emit(state.copyWith(
        status: ProfileStatus.success,
        successMessage: 'Certificate removed.',
      )),
    );
  }

  // ── Reset ────────────────────────────────────────────────────────────────────

  /// Call after handling an error/success in the UI to reset the state.
  void clearMessages() {
    emit(state.copyWith(
      status: ProfileStatus.loaded,
    ));
  }
}
