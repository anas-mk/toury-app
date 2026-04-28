import 'package:equatable/equatable.dart';

import '../../domain/entities/alternatives_response.dart';
import '../../domain/entities/booking_detail.dart';
import '../../domain/entities/helper_search_result.dart';

/// State machine for the Instant Trip Booking flow.
///
/// The flow is roughly:
///   Initial → Searching → HelpersLoaded
///                             │
///                             ▼
///                        Creating → Created → Waiting
///                                              │
///                       ┌──────────────────────┼──────────────────────┐
///                       ▼                      ▼                      ▼
///                  Accepted              Declined                Cancelled
///                                  (with alternatives)
abstract class InstantBookingState extends Equatable {
  const InstantBookingState();

  @override
  List<Object?> get props => [];
}

class InstantBookingInitial extends InstantBookingState {
  const InstantBookingInitial();
}

/// `POST /user/bookings/instant/search` is in flight.
class InstantBookingSearching extends InstantBookingState {
  const InstantBookingSearching();
}

class InstantBookingHelpersLoaded extends InstantBookingState {
  final List<HelperSearchResult> helpers;
  const InstantBookingHelpersLoaded(this.helpers);

  @override
  List<Object?> get props => [helpers];
}

/// `POST /user/bookings/instant` is in flight.
class InstantBookingCreating extends InstantBookingState {
  const InstantBookingCreating();
}

/// Booking created successfully — backend has put us in
/// `PendingHelperResponse` and is waiting on the helper.
class InstantBookingCreated extends InstantBookingState {
  final BookingDetail booking;
  const InstantBookingCreated(this.booking);

  @override
  List<Object?> get props => [booking];
}

/// We are sitting on the WaitingForHelper screen. Real-time + polling
/// updates flow into this state without changing it (state stays Waiting,
/// but the underlying booking detail can refresh).
class InstantBookingWaiting extends InstantBookingState {
  final BookingDetail booking;
  const InstantBookingWaiting(this.booking);

  @override
  List<Object?> get props => [booking];
}

/// Helper accepted — UI should push to BookingConfirmedPage.
class InstantBookingAccepted extends InstantBookingState {
  final BookingDetail booking;
  const InstantBookingAccepted(this.booking);

  @override
  List<Object?> get props => [booking];
}

/// Helper declined / expired / system asked the user to pick again — UI
/// should push to BookingAlternativesPage.
class InstantBookingDeclined extends InstantBookingState {
  final BookingDetail booking;
  final AlternativesResponse alternatives;
  const InstantBookingDeclined(this.booking, this.alternatives);

  @override
  List<Object?> get props => [booking, alternatives];
}

/// Booking was cancelled (by user, helper or system).
class InstantBookingCancelled extends InstantBookingState {
  final String reason;
  const InstantBookingCancelled(this.reason);

  @override
  List<Object?> get props => [reason];
}

class InstantBookingError extends InstantBookingState {
  final String message;
  const InstantBookingError(this.message);

  @override
  List<Object?> get props => [message];
}
