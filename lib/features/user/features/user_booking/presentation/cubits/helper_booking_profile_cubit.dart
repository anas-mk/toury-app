import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/helper_booking_profile.dart';
import '../../domain/usecases/instant/get_helper_profile_uc.dart';

abstract class HelperBookingProfileState extends Equatable {
  const HelperBookingProfileState();

  @override
  List<Object?> get props => [];
}

class HelperBookingProfileInitial extends HelperBookingProfileState {
  const HelperBookingProfileInitial();
}

class HelperBookingProfileLoading extends HelperBookingProfileState {
  const HelperBookingProfileLoading();
}

class HelperBookingProfileLoaded extends HelperBookingProfileState {
  final HelperBookingProfile profile;
  const HelperBookingProfileLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

class HelperBookingProfileError extends HelperBookingProfileState {
  final String message;
  const HelperBookingProfileError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Single-shot loader for `GET /user/bookings/helpers/{helperId}/profile`.
class HelperBookingProfileCubit extends Cubit<HelperBookingProfileState> {
  final GetHelperBookingProfileUC getHelperBookingProfileUC;

  HelperBookingProfileCubit({required this.getHelperBookingProfileUC})
      : super(const HelperBookingProfileInitial());

  Future<void> load(String helperId) async {
    emit(const HelperBookingProfileLoading());
    final result = await getHelperBookingProfileUC(helperId);
    result.fold(
      (failure) => emit(HelperBookingProfileError(failure.message)),
      (profile) => emit(HelperBookingProfileLoaded(profile)),
    );
  }
}
