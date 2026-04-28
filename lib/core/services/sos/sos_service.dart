import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/api_config.dart';
import '../notifications/notification_router.dart';
import '../realtime/realtime_logger.dart';
import 'active_sos_state.dart';
import 'sos_background_task.dart';

class TriggerSosResult {
  const TriggerSosResult._({required this.success, this.state, this.message});

  final bool success;
  final ActiveSosState? state;
  final String? message;

  factory TriggerSosResult.success(ActiveSosState state) =>
      TriggerSosResult._(success: true, state: state);

  factory TriggerSosResult.failure(String message) =>
      TriggerSosResult._(success: false, message: message);
}

class CancelSosResult {
  const CancelSosResult._({required this.success, this.message});

  final bool success;
  final String? message;

  factory CancelSosResult.success() => const CancelSosResult._(success: true);

  factory CancelSosResult.failure(String message) =>
      CancelSosResult._(success: false, message: message);
}

class SosService {
  SosService({required Dio dio, required SharedPreferences prefs})
    : _dio = dio,
      _prefs = prefs {
    _activeSos = loadFromPrefs();
    _attachBackgroundStopListener();
  }

  static const String _activeSosPrefsKey = 'active_sos_v1';

  final Dio _dio;
  final SharedPreferences _prefs;
  final FlutterBackgroundService _backgroundService =
      FlutterBackgroundService();
  final StreamController<ActiveSosState?> _activeController =
      StreamController<ActiveSosState?>.broadcast();

  ActiveSosState? _activeSos;
  bool _backgroundConfigured = false;
  bool _backgroundPermissionPrompted = false;
  StreamSubscription<Map<String, dynamic>?>? _backgroundStopSub;

  ActiveSosState? get activeSos => _activeSos;
  Stream<ActiveSosState?> get activeSosStream => _activeController.stream;

  Future<TriggerSosResult> trigger({
    required String bookingId,
    required String reason,
    String? note,
  }) async {
    RealtimeLogger.instance.log(
      'SOS',
      'trigger.start',
      'bookingId=$bookingId reason=$reason',
    );

    final position = await _tryGetCurrentPosition();
    final body = <String, dynamic>{
      'reason': reason,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      if (position != null) 'latitude': position.latitude,
      if (position != null) 'longitude': position.longitude,
    };

    if (position == null) {
      RealtimeLogger.instance.log(
        'SOS',
        'trigger.gps.skip',
        'no fix within timeout — proceeding without coordinates',
      );
    }

    try {
      final response = await _dio.post(
        ApiConfig.triggerSos(bookingId),
        data: body,
      );
      final statusCode = response.statusCode ?? 0;
      final responseMap = _asMap(response.data);
      final message = _message(responseMap) ?? 'SOS request failed';
      final data = _dataMap(responseMap);

      if (statusCode >= 200 && statusCode < 300) {
        final state = _stateFromResponseData(
          data,
          fallbackBookingId: bookingId,
          fallbackReason: reason,
        );
        if (state == null) {
          RealtimeLogger.instance.log(
            'SOS',
            'trigger.fail',
            '2xx response missing data.id',
            isError: true,
          );
          return TriggerSosResult.failure(
            'SOS triggered but response was incomplete.',
          );
        }
        await _setActive(state);
        await _startBackgroundStreaming(state: state);
        RealtimeLogger.instance.log(
          'SOS',
          'trigger.ok',
          'sosId=${state.sosId} bookingId=${state.bookingId}',
        );
        return TriggerSosResult.success(state);
      }

      final existing = _stateFromResponseData(
        data,
        fallbackBookingId: bookingId,
        fallbackReason: reason,
      );
      if (existing != null && _looksLikeAlreadyActive(message)) {
        await _setActive(existing);
        await _startBackgroundStreaming(state: existing);
        RealtimeLogger.instance.log(
          'SOS',
          'trigger.existing',
          'sosId=${existing.sosId} bookingId=${existing.bookingId}',
        );
        return TriggerSosResult.success(existing);
      }

      RealtimeLogger.instance.log(
        'SOS',
        'trigger.fail',
        'status=$statusCode message=$message',
        isError: true,
      );
      return TriggerSosResult.failure(message);
    } on DioException catch (e) {
      final responseMap = _asMap(e.response?.data);
      final message =
          _message(responseMap) ?? e.message ?? 'SOS request failed';
      RealtimeLogger.instance.log(
        'SOS',
        'trigger.error',
        message,
        isError: true,
      );
      return TriggerSosResult.failure(message);
    } catch (e) {
      RealtimeLogger.instance.log('SOS', 'trigger.error', '$e', isError: true);
      return TriggerSosResult.failure('SOS request failed. Please try again.');
    }
  }

  Future<CancelSosResult> cancel({String reason = 'false alarm'}) async {
    final current = _activeSos;
    if (current == null) {
      return CancelSosResult.failure('No active SOS to cancel.');
    }

    RealtimeLogger.instance.log(
      'SOS',
      'cancel.start',
      'sosId=${current.sosId} bookingId=${current.bookingId}',
    );

    try {
      final response = await _dio.patch(
        ApiConfig.cancelSos(current.sosId),
        data: {'reason': reason},
      );
      final statusCode = response.statusCode ?? 0;
      final responseMap = _asMap(response.data);
      final message = _message(responseMap) ?? 'SOS cancel failed';

      if (statusCode >= 200 && statusCode < 300) {
        await _stopBackgroundStreaming(reason: 'cancelled');
        await _clearActive();
        RealtimeLogger.instance.log(
          'SOS',
          'cancel.ok',
          'sosId=${current.sosId}',
        );
        return CancelSosResult.success();
      }

      RealtimeLogger.instance.log(
        'SOS',
        'cancel.fail',
        'status=$statusCode message=$message',
        isError: true,
      );
      return CancelSosResult.failure(message);
    } on DioException catch (e) {
      final responseMap = _asMap(e.response?.data);
      final message = _message(responseMap) ?? e.message ?? 'SOS cancel failed';
      RealtimeLogger.instance.log(
        'SOS',
        'cancel.error',
        message,
        isError: true,
      );
      return CancelSosResult.failure(message);
    } catch (e) {
      RealtimeLogger.instance.log('SOS', 'cancel.error', '$e', isError: true);
      return CancelSosResult.failure('SOS cancel failed. Please try again.');
    }
  }

  void _attachBackgroundStopListener() {
    _backgroundStopSub ??= _backgroundService.on('sos.stop').listen((
      event,
    ) async {
      final reason = event?['reason']?.toString() ?? 'unknown';
      final code = event?['code']?.toString();
      final withCode = (code == null || code.isEmpty)
          ? reason
          : '$reason ($code)';
      RealtimeLogger.instance.log(
        'SOS',
        'bg.stop',
        'reason=$withCode',
        isError: reason == '4xx',
      );
      await _clearActive();
      _postRootSnack('SOS streaming stopped: $withCode');
    });
  }

  Future<void> _startBackgroundStreaming({
    required ActiveSosState state,
  }) async {
    try {
      await _ensureBackgroundConfigured();

      final canStart = await _ensureBackgroundPermission();
      if (!canStart) {
        RealtimeLogger.instance.log(
          'SOS',
          'bg.start.skip',
          'user chose Open Settings from permission dialog',
        );
        return;
      }

      final running = await _backgroundService.isRunning();
      if (running) {
        _backgroundService.invoke('cancel', {'reason': 'restart'});
        await Future<void>.delayed(const Duration(milliseconds: 200));
        _backgroundService.invoke('stopService');
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }

      final started = await _backgroundService.startService();
      RealtimeLogger.instance.log(
        'SOS',
        'bg.start',
        'started=$started bookingId=${state.bookingId} sosId=${state.sosId}',
      );
    } catch (e) {
      RealtimeLogger.instance.log('SOS', 'bg.start.error', '$e', isError: true);
    }
  }

  Future<void> _stopBackgroundStreaming({required String reason}) async {
    try {
      final running = await _backgroundService.isRunning();
      if (!running) return;
      _backgroundService.invoke('cancel', {'reason': reason});
      await Future<void>.delayed(const Duration(milliseconds: 200));
      _backgroundService.invoke('stopService');
      RealtimeLogger.instance.log('SOS', 'bg.stop.requested', 'reason=$reason');
    } catch (e) {
      RealtimeLogger.instance.log('SOS', 'bg.stop.error', '$e', isError: true);
    }
  }

  Future<void> _ensureBackgroundConfigured() async {
    if (_backgroundConfigured) return;
    final configured = await SosBackgroundTask.configure();
    _backgroundConfigured = configured;
    RealtimeLogger.instance.log('SOS', 'bg.configure', 'ok=$configured');
  }

  Future<bool> _ensureBackgroundPermission() async {
    if (!Platform.isAndroid) return true;

    var status = await Permission.locationAlways.status;
    if (status.isGranted) return true;

    status = await Permission.locationAlways.request();
    if (status.isGranted) return true;

    if (_backgroundPermissionPrompted) {
      return true;
    }

    final context = NotificationRouter.instance.navigatorContext;
    if (context == null || !context.mounted) {
      return true;
    }
    _backgroundPermissionPrompted = true;

    final choice = await showDialog<_BackgroundPermissionChoice>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Background location permission'),
          content: const Text(
            'Without background permission, your live location will only be '
            'shared while the app is open. Continue anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(
                dialogContext,
              ).pop(_BackgroundPermissionChoice.openSettings),
              child: const Text('Open Settings'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(
                dialogContext,
              ).pop(_BackgroundPermissionChoice.continueAnyway),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    if (choice == _BackgroundPermissionChoice.openSettings) {
      await openAppSettings();
      return false;
    }
    // Dismiss / back button defaults to continue.
    return true;
  }

  void _postRootSnack(String text) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = NotificationRouter.instance.navigatorContext;
      if (ctx == null || !ctx.mounted) return;
      ScaffoldMessenger.maybeOf(
        ctx,
      )?.showSnackBar(SnackBar(content: Text(text)));
    });
  }

  ActiveSosState? loadFromPrefs() {
    final raw = _prefs.getString(_activeSosPrefsKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return ActiveSosState.fromJson(Map<String, dynamic>.from(decoded));
    } catch (e) {
      RealtimeLogger.instance.log(
        'SOS',
        'prefs.load.error',
        '$e',
        isError: true,
      );
      return null;
    }
  }

  Future<void> _setActive(ActiveSosState state) async {
    _activeSos = state;
    await _saveToPrefs(state);
    _activeController.add(state);
  }

  Future<void> _clearActive() async {
    _activeSos = null;
    await _clearPrefs();
    _activeController.add(null);
  }

  Future<void> _saveToPrefs(ActiveSosState state) async {
    await _prefs.setString(_activeSosPrefsKey, jsonEncode(state.toJson()));
  }

  Future<void> _clearPrefs() async {
    await _prefs.remove(_activeSosPrefsKey);
  }

  Future<Position?> _tryGetCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      RealtimeLogger.instance.log('SOS', 'gps.error', '$e', isError: true);
      return null;
    }
  }

  ActiveSosState? _stateFromResponseData(
    Map<String, dynamic>? data, {
    required String fallbackBookingId,
    required String fallbackReason,
  }) {
    if (data == null) return null;
    final sosId = data['id']?.toString() ?? data['Id']?.toString();
    if (sosId == null || sosId.isEmpty) return null;
    final bookingId =
        data['bookingId']?.toString() ??
        data['BookingId']?.toString() ??
        fallbackBookingId;
    final startedAtRaw =
        data['createdAt']?.toString() ?? data['CreatedAt']?.toString();
    final startedAt = startedAtRaw == null || startedAtRaw.isEmpty
        ? DateTime.now().toUtc()
        : DateTime.tryParse(startedAtRaw)?.toUtc() ?? DateTime.now().toUtc();
    final reason =
        data['reason']?.toString() ??
        data['Reason']?.toString() ??
        fallbackReason;

    return ActiveSosState(
      sosId: sosId,
      bookingId: bookingId,
      startedAt: startedAt,
      reason: reason,
    );
  }

  Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  Map<String, dynamic>? _dataMap(Map<String, dynamic>? envelope) {
    final data = envelope?['data'] ?? envelope?['Data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  String? _message(Map<String, dynamic>? envelope) {
    return envelope?['message']?.toString() ??
        envelope?['Message']?.toString() ??
        envelope?['error']?.toString();
  }

  bool _looksLikeAlreadyActive(String message) {
    final lower = message.toLowerCase();
    return lower.contains('already') && lower.contains('active sos');
  }
}

enum _BackgroundPermissionChoice { continueAnyway, openSettings }
