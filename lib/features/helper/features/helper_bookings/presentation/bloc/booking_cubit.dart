import 'package:flutter_bloc/flutter_bloc.dart';
import 'booking_state.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/booking_status.dart';

class BookingCubit extends Cubit<BookingState> {
  BookingCubit() : super(BookingIdle());

  void goOnline() {
    if (state is BookingIdle || state is BookingCancelled) {
      emit(BookingSearching());
    }
  }

  void goOffline() {
    if (state is BookingSearching || state is BookingCancelled) {
      emit(BookingIdle());
    }
  }

  void receiveIncomingBooking(Booking booking) {
    if (state is BookingSearching) {
      final updatedBooking = booking.copyWith(status: BookingStatus.incomingRequest);
      emit(BookingIncomingRequest(updatedBooking));
    }
  }

  void acceptBooking() {
    if (state is BookingIncomingRequest) {
      final booking = (state as BookingIncomingRequest).booking;
      final updatedBooking = booking.copyWith(status: BookingStatus.accepted);
      emit(BookingAccepted(updatedBooking));
    }
  }

  void rejectBooking() {
    if (state is BookingIncomingRequest) {
      emit(BookingSearching());
    }
  }

  void startNavigationToPickup() {
    if (state is BookingAccepted) {
      final booking = (state as BookingAccepted).booking;
      final updatedBooking = booking.copyWith(status: BookingStatus.navigatingToPickup);
      emit(BookingNavigatingToPickup(updatedBooking));
    }
  }

  void markArrived() {
    if (state is BookingNavigatingToPickup) {
      final booking = (state as BookingNavigatingToPickup).booking;
      final updatedBooking = booking.copyWith(status: BookingStatus.arrived);
      emit(BookingArrived(updatedBooking));
    }
  }

  void startTrip() {
    if (state is BookingArrived) {
      final booking = (state as BookingArrived).booking;
      final updatedBooking = booking.copyWith(status: BookingStatus.tripStarted);
      emit(BookingTripStarted(updatedBooking));
    }
  }

  void startTripInProgress() {
    if (state is BookingTripStarted) {
      final booking = (state as BookingTripStarted).booking;
      final updatedBooking = booking.copyWith(status: BookingStatus.tripInProgress);
      emit(BookingTripInProgress(updatedBooking));
    }
  }

  void endTrip() {
    if (state is BookingTripInProgress || state is BookingTripStarted) {
      final booking = _getCurrentBooking();
      if (booking != null) {
        final updatedBooking = booking.copyWith(status: BookingStatus.tripEnding);
        emit(BookingTripEnding(updatedBooking));
      }
    }
  }

  void completeTrip() {
    if (state is BookingTripEnding) {
      final booking = (state as BookingTripEnding).booking;
      final updatedBooking = booking.copyWith(status: BookingStatus.completed);
      emit(BookingCompleted(updatedBooking));
    }
  }

  void cancelTrip(String reason) {
    // Cannot cancel from Idle or Completed
    if (state is! BookingIdle && state is! BookingCompleted && state is! BookingCancelled) {
      final booking = _getCurrentBooking();
      final updatedBooking = booking?.copyWith(status: BookingStatus.cancelled, cancelReason: reason);
      emit(BookingCancelled(reason, booking: updatedBooking));
    }
  }

  /// Helper to safely extract the booking entity from any active state
  Booking? _getCurrentBooking() {
    if (state is BookingIncomingRequest) return (state as BookingIncomingRequest).booking;
    if (state is BookingAccepted) return (state as BookingAccepted).booking;
    if (state is BookingNavigatingToPickup) return (state as BookingNavigatingToPickup).booking;
    if (state is BookingArrived) return (state as BookingArrived).booking;
    if (state is BookingTripStarted) return (state as BookingTripStarted).booking;
    if (state is BookingTripInProgress) return (state as BookingTripInProgress).booking;
    if (state is BookingTripEnding) return (state as BookingTripEnding).booking;
    if (state is BookingCompleted) return (state as BookingCompleted).booking;
    return null;
  }
}
