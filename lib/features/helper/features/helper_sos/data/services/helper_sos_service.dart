import 'dart:async';

class HelperSosService {
  // This will handle API calls once backend is ready
  
  Future<void> triggerPanicAlert({required double lat, required double lng}) async {
    // API Placeholder: POST /api/helper/sos/panic
    await Future.delayed(const Duration(seconds: 1)); // Simulate network
  }

  Future<void> stopPanicAlert() async {
    // API Placeholder: DELETE /api/helper/sos/panic
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
