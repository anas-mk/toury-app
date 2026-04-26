import 'dart:async';
import 'package:signalr_netcore/hub_connection.dart';
import '../models/helper_report_models.dart';

class HelperReportsSignalRService {
  final HubConnection? _hubConnection; // Reusing or separate? Let's assume shared hub connection if possible, or new one.
  
  final _resolutionController = StreamController<HelperReportModel>.broadcast();
  Stream<HelperReportModel> get resolutionStream => _resolutionController.stream;

  HelperReportsSignalRService(this._hubConnection) {
    _initListeners();
  }

  void _initListeners() {
    if (_hubConnection == null) return;

    _hubConnection!.on('HelperReportResolved', (args) {
      if (args != null && args.isNotEmpty) {
        final data = args[0] as Map<String, dynamic>;
        _resolutionController.add(HelperReportModel.fromJson(data));
      }
    });
  }

  void dispose() {
    _resolutionController.close();
  }
}
