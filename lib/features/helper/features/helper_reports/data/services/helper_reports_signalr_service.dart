import 'dart:async';
import '../../../../../../core/services/signalr/booking_tracking_hub_service.dart';
import '../models/helper_report_models.dart';

class HelperReportsSignalRService {
  final BookingTrackingHubService _hubService;

  final _resolutionController = StreamController<HelperReportModel>.broadcast();
  Stream<HelperReportModel> get resolutionStream => _resolutionController.stream;
  StreamSubscription? _hubSub;

  HelperReportsSignalRService(this._hubService) {
    _initListeners();
  }

  void _initListeners() {
    _hubSub?.cancel();
    _hubSub = _hubService.helperReportResolvedStream.listen((event) {
      _resolutionController.add(
        HelperReportModel(
          reportId: event.reportId,
          reason: event.resolution ?? 'Report Resolved',
          details: event.notes ?? '',
          isResolved: true,
          resolutionNote: event.notes,
          createdAt: event.occurredAt ?? DateTime.now().toUtc(),
          resolvedAt: event.occurredAt ?? DateTime.now().toUtc(),
        ),
      );
    });
  }

  void dispose() {
    _hubSub?.cancel();
    _resolutionController.close();
  }
}
