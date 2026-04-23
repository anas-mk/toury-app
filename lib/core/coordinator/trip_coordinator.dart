import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../features/helper/features/helper_bookings/presentation/bloc/booking_cubit.dart';
import '../../features/helper/features/helper_bookings/presentation/bloc/booking_state.dart';
import '../../features/helper/features/location/presentation/bloc/location_cubit.dart';
import '../../features/helper/features/location/presentation/bloc/route_cubit.dart';
import '../../features/helper/features/chat/presentation/bloc/chat_cubit.dart';

class TripCoordinator {
  final BookingCubit bookingCubit;
  final LocationCubit locationCubit;
  final RouteCubit routeCubit;
  final ChatCubit chatCubit;

  StreamSubscription<BookingState>? _bookingSubscription;

  TripCoordinator({
    required this.bookingCubit,
    required this.locationCubit,
    required this.routeCubit,
    required this.chatCubit,
  }) {
    _startListening();
  }

  void _startListening() {
    _bookingSubscription = bookingCubit.stream.listen(_onBookingStateChanged);
  }

  void _onBookingStateChanged(BookingState state) {
    debugPrint('TripCoordinator: Received BookingState -> ${state.runtimeType}');

    if (state is BookingNavigatingToPickup) {
      locationCubit.startTracking();
      routeCubit.buildRoute(
        destinationLat: state.booking.pickupLatitude,
        destinationLng: state.booking.pickupLongitude,
      );
      chatCubit.connect(state.booking.id);
    } 
    else if (state is BookingArrived) {
      // Keep tracking, just log the waiting mode switch
      debugPrint('TripCoordinator: Helper arrived. Enabling waiting mode/timer.');
    } 
    else if (state is BookingTripInProgress) {
      routeCubit.updateRoute(
        destinationLat: state.booking.dropoffLatitude,
        destinationLng: state.booking.dropoffLongitude,
      );
    } 
    else if (state is BookingCompleted) {
      locationCubit.stopTracking();
      chatCubit.disconnect();
      routeCubit.clearRoute();
    } 
    else if (state is BookingCancelled) {
      locationCubit.stopTracking();
      chatCubit.disconnect();
      routeCubit.clearRoute();
    }
    else if (state is BookingIdle) {
      locationCubit.stopTracking();
      chatCubit.disconnect();
      routeCubit.clearRoute();
    }
  }

  void dispose() {
    _bookingSubscription?.cancel();
  }
}
