import 'dart:async';
import '../../../../../../core/network/websocket_service.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/booking_status.dart';

class BookingRemoteDataSource {
  final WebSocketService webSocketService;

  final StreamController<Booking> _incomingController = StreamController.broadcast();
  final StreamController<Booking> _updatesController = StreamController.broadcast();

  BookingRemoteDataSource(this.webSocketService) {
    _listenToWebSocket();
  }

  Stream<Booking> get incomingBookingStream => _incomingController.stream;
  Stream<Booking> get activeBookingStream => _updatesController.stream;

  void _listenToWebSocket() {
    webSocketService.messages.listen((message) {
      final event = message['event'] as String;
      final data = message['data'] as Map<String, dynamic>;

      if (event == 'new_booking_request') {
        // In real app: final booking = BookingModel.fromJson(data);
        // _incomingController.add(booking);
        print('BookingRemoteDataSource: Received new booking request via WS');
      } 
      else if (event == 'booking_updated') {
        // In real app: final booking = BookingModel.fromJson(data);
        // _updatesController.add(booking);
        print('BookingRemoteDataSource: Received booking update via WS');
      }
    });
  }

  Future<void> acceptBooking(String bookingId) async {
    // Usually a REST call, but can be WS
    webSocketService.send('accept_booking', {'bookingId': bookingId});
  }

  Future<void> rejectBooking(String bookingId) async {
    webSocketService.send('reject_booking', {'bookingId': bookingId});
  }

  Future<void> updateBookingStatus(String bookingId, BookingStatus status) async {
    webSocketService.send('update_booking_status', {
      'bookingId': bookingId,
      'status': status.name,
    });
  }
}
