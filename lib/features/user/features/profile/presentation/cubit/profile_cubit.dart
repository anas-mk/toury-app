import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/widgets/user_avatar.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../user_booking/domain/usecases/get_my_bookings_usecase.dart';
import '../../../user_ratings/domain/entities/rating_entity.dart';
import '../../../user_ratings/domain/usecases/get_user_rating_summary_usecase.dart';

/// Tourist account/profile cubit.
///
/// Loads everything the redesigned profile screen needs:
///   • cached `UserEntity` (already kept fresh after every login / register
///     / update-profile call — see `AuthLocalDataSource.cacheUser`)
///   • completed-trips count (from `/user/bookings`)
///   • aggregate rating summary (from `/ratings/user/{id}/summary`)
///
/// Trips count and rating are best-effort: if either endpoint fails, we
/// degrade gracefully (`null`) so the rest of the profile keeps rendering.
class TouristProfileState extends Equatable {
  final UserEntity? user;
  final int? tripsCount;
  final RatingSummaryEntity? ratingSummary;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  const TouristProfileState({
    this.user,
    this.tripsCount,
    this.ratingSummary,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
  });

  const TouristProfileState.initial() : this();

  TouristProfileState copyWith({
    UserEntity? user,
    int? tripsCount,
    RatingSummaryEntity? ratingSummary,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return TouristProfileState(
      user: user ?? this.user,
      tripsCount: tripsCount ?? this.tripsCount,
      ratingSummary: ratingSummary ?? this.ratingSummary,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        user,
        tripsCount,
        ratingSummary,
        isLoading,
        isSaving,
        errorMessage,
        successMessage,
      ];
}

class TouristProfileCubit extends Cubit<TouristProfileState> {
  final AuthRepository authRepository;
  final GetMyBookingsUseCase getMyBookingsUseCase;
  final GetUserRatingSummaryUseCase getUserRatingSummaryUseCase;

  TouristProfileCubit({
    required this.authRepository,
    required this.getMyBookingsUseCase,
    required this.getUserRatingSummaryUseCase,
  }) : super(const TouristProfileState.initial());

  /// Loads the cached user immediately, then refreshes trips + rating
  /// in parallel. We DO NOT block the UI on those side calls.
  Future<void> load() async {
    emit(state.copyWith(isLoading: true, clearMessages: true));

    final cached = await authRepository.getCachedUser();
    final user = cached.fold((_) => null, (u) => u);

    emit(state.copyWith(user: user, isLoading: false));

    if (user == null) return;

    await Future.wait([
      _loadTripsCount(),
      _loadRatingSummary(user),
    ]);
  }

  /// Sends a partial update to `PUT /Auth/update-profile`. Pass only the
  /// fields that changed; everything else stays untouched server-side.
  /// On success, the cached user is refreshed and we re-fetch the rating
  /// summary (in case `userId` shape changed; cheap and safe).
  Future<void> updateField({
    String? userName,
    String? phoneNumber,
    String? gender,
    DateTime? birthDate,
    String? country,
    File? profileImage,
    String? successLabel,
  }) async {
    emit(state.copyWith(isSaving: true, clearMessages: true));

    final result = await authRepository.patchProfile(
      userName: userName,
      phoneNumber: phoneNumber,
      gender: gender,
      birthDate: birthDate,
      country: country,
      profileImage: profileImage,
    );

    await result.fold(
      (failure) async => emit(state.copyWith(
        isSaving: false,
        errorMessage: failure.message,
      )),
      (user) async {
        emit(state.copyWith(
          user: user,
          isSaving: false,
          successMessage: successLabel ?? 'Profile updated',
        ));
        // Broadcast the new avatar to every visible top-bar / list item.
        await UserAvatarController.instance.refresh();
      },
    );
  }

  void clearMessages() {
    if (state.errorMessage != null || state.successMessage != null) {
      emit(state.copyWith(clearMessages: true));
    }
  }

  Future<void> _loadTripsCount() async {
    try {
      // page=1, pageSize=1 is the cheapest way to read the server's
      // `totalCount` for the user's bookings. We display the total
      // number of trips (any status) — the bento stat is just "Trips",
      // matching the new design.
      final result = await getMyBookingsUseCase(page: 1, pageSize: 1);
      result.fold(
        (_) => null,
        (paged) => emit(state.copyWith(tripsCount: paged.totalCount)),
      );
    } catch (_) {
      // Soft fail — leave tripsCount null.
    }
  }

  Future<void> _loadRatingSummary(UserEntity user) async {
    try {
      final id = user.userId ?? user.id?.toString();
      if (id == null || id.isEmpty) return;
      final result = await getUserRatingSummaryUseCase(id);
      result.fold(
        (_) => null,
        (summary) => emit(state.copyWith(ratingSummary: summary)),
      );
    } catch (_) {
      // Soft fail — leave ratingSummary null.
    }
  }

  /// Re-reads the cached user (used after the user updates their profile).
  Future<void> refreshCachedUser() async {
    final cached = await authRepository.getCachedUser();
    final user = cached.fold((_) => state.user, (u) => u);
    emit(state.copyWith(user: user));
  }
}
