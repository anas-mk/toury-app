import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/helper_booking_entities.dart';
import '../../domain/usecases/helper_bookings_usecases.dart';
import 'dart:async';
import '../../../../../../core/services/signalr/booking_tracking_hub_service.dart';

// ACTIVE BOOKING CUBIT
abstract class ActiveBookingState extends Equatable {
  const ActiveBookingState();
  @override List<Object?> get props => [];
}
class ActiveBookingInitial extends ActiveBookingState { const ActiveBookingInitial(); }
class ActiveBookingLoading extends ActiveBookingState { const ActiveBookingLoading(); }
class ActiveBookingLoaded extends ActiveBookingState {
  final HelperBooking? booking;
  const ActiveBookingLoaded(this.booking);
  @override List<Object?> get props => [booking];
}
class ActiveBookingError extends ActiveBookingState {
  final String message;
  const ActiveBookingError(this.message);
  @override List<Object?> get props => [message];
}

class ActiveBookingCubit extends Cubit<ActiveBookingState> {
  final GetActiveBookingUseCase _getActive;
  final GetHelperBookingDetailsUseCase _getDetails;
  final BookingTrackingHubService _hubService;
  StreamSubscription? _hubSub;
  Timer? _hubDebounce;
  bool _inFlight = false;
  String? _currentId;

  ActiveBookingCubit(
    this._getActive, 
    this._getDetails,
    this._hubService,
  ) : super(const ActiveBookingInitial()) {
    _listenToHub();
  }

  void _listenToHub() {
    _hubSub?.cancel();
    _hubSub = _hubService.statusStream.listen((event) {
      // Re-fetch active booking on any status change event
      _hubDebounce?.cancel();
      _hubDebounce = Timer(const Duration(milliseconds: 700), () {
        if (isClosed) return;
        load(silent: true);
      });
    });
  }

  Future<void> load({bool silent = false}) async {
    if (_inFlight) return;
    _inFlight = true;
    if (!silent) emit(const ActiveBookingLoading());
    try {
      final booking = await _getActive();
      if (isClosed) return;
      
      if (booking == null && _currentId != null) {
        // Fallback to specific ID if active is null but we were tracking one
        return loadById(_currentId!, silent: silent);
      }
      
      emit(ActiveBookingLoaded(booking));
    } catch (e) {
      if (isClosed) return;
      emit(ActiveBookingError(e.toString()));
    } finally {
      _inFlight = false;
    }
  }

  Future<void> loadById(String id, {bool silent = false}) async {
    if (_inFlight) return;
    _inFlight = true;
    _currentId = id;
    if (!silent) emit(const ActiveBookingLoading());
    try {
      final booking = await _getDetails(id);
      if (isClosed) return;
      emit(ActiveBookingLoaded(booking));
    } catch (e) {
      if (isClosed) return;
      emit(ActiveBookingError(e.toString()));
    } finally {
      _inFlight = false;
    }
  }

  void clearCurrentId() => _currentId = null;

  @override
  Future<void> close() {
    _hubDebounce?.cancel();
    _hubSub?.cancel();
    return super.close();
  }
}

