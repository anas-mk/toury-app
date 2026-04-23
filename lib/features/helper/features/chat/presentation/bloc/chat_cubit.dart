import 'package:flutter_bloc/flutter_bloc.dart';

class ChatCubit extends Cubit<void> {
  ChatCubit() : super(null);

  void connect(String bookingId) {
    // Mock implementation
    print('ChatCubit: Connected to chat room for booking $bookingId.');
  }

  void disconnect() {
    // Mock implementation
    print('ChatCubit: Disconnected from chat room.');
  }
}
