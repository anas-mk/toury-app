import '../../../../../../core/network/websocket_service.dart';
import '../../domain/entities/location_point.dart';

class LocationRemoteDataSource {
  final WebSocketService webSocketService;
  
  // Offline Queue for Connection Drops
  final List<LocationPoint> _offlineQueue = [];

  LocationRemoteDataSource(this.webSocketService);

  Future<void> broadcastLocation(LocationPoint point, String bookingId) async {
    final payload = {
      'lat': point.latitude,
      'lng': point.longitude,
      'heading': point.heading,
      'speed': point.speed,
      'timestamp': point.timestamp.toIso8601String(),
      'bookingId': bookingId,
    };

    if (webSocketService.isConnected) {
      try {
        // 1. If we reconnected, sync old queue first
        await syncOfflineLocations(bookingId);
        
        // 2. Send current point
        webSocketService.send('location_update', payload);
      } catch (e) {
        _cacheLocation(point);
      }
    } else {
      _cacheLocation(point);
    }
  }

  void _cacheLocation(LocationPoint point) {
    _offlineQueue.add(point);
    print('LocationRemoteDataSource: Connection drop. Cached point. Queue size: ${_offlineQueue.length}');
  }

  Future<void> syncOfflineLocations(String bookingId) async {
    if (!webSocketService.isConnected || _offlineQueue.isEmpty) return;

    final batchPayload = _offlineQueue.map((p) => {
      'lat': p.latitude,
      'lng': p.longitude,
      'heading': p.heading,
      'speed': p.speed,
      'timestamp': p.timestamp.toIso8601String(),
    }).toList();

    webSocketService.send('location_batch_update', {
      'bookingId': bookingId,
      'points': batchPayload
    });

    print('LocationRemoteDataSource: Synced ${_offlineQueue.length} offline points after reconnect.');
    _offlineQueue.clear();
  }
}
