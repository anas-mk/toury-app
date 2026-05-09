import 'package:dio/dio.dart';
import '../../../../../../core/config/api_config.dart';

class HelperSosService {
  final Dio dio;
  HelperSosService(this.dio);

  String? _activeSosId;
  String? get activeSosId => _activeSosId;
  bool get hasActiveSos => _activeSosId != null && _activeSosId!.isNotEmpty;

  Future<void> triggerPanicAlert({
    required String bookingId,
    required double lat,
    required double lng,
    String? reason,
    String? note,
  }) async {
    if (bookingId.trim().isEmpty) {
      throw Exception('Missing booking ID for SOS trigger');
    }
    final res = await dio.post(
      ApiConfig.helperTriggerSos(bookingId),
      data: {
        'latitude': lat,
        'longitude': lng,
        if (reason != null) 'reason': reason,
        if (note != null) 'note': note,
      },
    );
    
    if (res.data is Map) {
      if (res.data['success'] == false) {
        throw Exception(res.data['message'] ?? 'Failed to trigger SOS');
      }
      if (res.data['data'] is Map) {
        _activeSosId = res.data['data']['id']?.toString();
      }
    }
  }

  Future<void> stopPanicAlert() async {
    if (!hasActiveSos) return;
    
    await dio.patch(ApiConfig.helperCancelSos(_activeSosId!));
    _activeSosId = null;
  }
}
