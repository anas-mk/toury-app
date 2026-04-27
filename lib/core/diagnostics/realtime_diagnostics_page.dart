import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signalr_netcore/hub_connection.dart';

import '../di/injection_container.dart';
import '../services/notifications/device_info_helper.dart';
import '../services/notifications/messaging_service.dart';
import '../services/realtime/event_dedup_cache.dart';
import '../services/realtime/realtime_logger.dart';
import '../services/signalr/booking_tracking_hub_service.dart';

/// Hidden `/dev/realtime` page — wired into the router behind a known URL,
/// not in the bottom nav. Lets QA verify:
///   - SignalR connection state,
///   - registered handler list,
///   - last 50 realtime events (with eventId, source, summary),
///   - last FCM token (last 10 chars),
///   - device id,
///   - dedup-cache size,
///   - "Send test push" button (POST /api/notifications/devices/test).
class RealtimeDiagnosticsPage extends StatefulWidget {
  const RealtimeDiagnosticsPage({super.key});

  @override
  State<RealtimeDiagnosticsPage> createState() =>
      _RealtimeDiagnosticsPageState();
}

class _RealtimeDiagnosticsPageState extends State<RealtimeDiagnosticsPage> {
  late final BookingTrackingHubService _hub = sl<BookingTrackingHubService>();
  late final MessagingService _messaging = sl<MessagingService>();
  late final DeviceInfoHelper _deviceInfo = sl<DeviceInfoHelper>();

  String? _deviceId;
  HubConnectionState _state = HubConnectionState.Disconnected;
  StreamSubscription<RealtimeLogEntry>? _logSub;
  StreamSubscription<HubConnectionState>? _stateSub;
  bool _sendingTest = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    _state = _hub.connectionState;
    _stateSub = _hub.connectionStateStream.listen((s) {
      if (!mounted) return;
      setState(() => _state = s);
    });
    _logSub = RealtimeLogger.instance.stream.listen((_) {
      if (mounted) setState(() {});
    });
    _deviceInfo.getDeviceId().then((id) {
      if (mounted) setState(() => _deviceId = id);
    });
  }

  @override
  void dispose() {
    _logSub?.cancel();
    _stateSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = RealtimeLogger.instance.entries.take(50).toList();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Realtime / Push diagnostics'),
        actions: [
          IconButton(
            tooltip: 'Reconnect',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _hub.start(),
          ),
          IconButton(
            tooltip: 'Ping',
            icon: const Icon(Icons.network_ping_rounded),
            onPressed: _hub.isConnected ? () => _hub.ping() : null,
          ),
          IconButton(
            tooltip: 'Clear log',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () {
              RealtimeLogger.instance.clear();
              setState(() {});
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatusCard(
            state: _state,
            handlers: _hub.registeredHandlers,
            dedupSize: EventDedupCache.instance.size,
            fcmTail: _fcmTail(),
            deviceId: _deviceId ?? '…',
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: _sendingTest
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
            onPressed: _sendingTest ? null : _onSendTestPush,
            label: const Text('Send test push to this device'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.notifications_active_outlined),
            onPressed: () {
              _messaging.debugFakeForegroundHeadsUp();
              setState(() {
                _testResult = 'Synthetic foreground heads-up fired (local).';
              });
            },
            label: const Text('Fake foreground heads-up (local)'),
          ),
          if (_testResult != null) ...[
            const SizedBox(height: 8),
            Text(_testResult!, style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: 16),
          Text(
            'Last 50 realtime events',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (entries.isEmpty)
            const Text('No events yet — try pushing one.')
          else
            ...entries.map((e) => _LogTile(entry: e)),
        ],
      ),
    );
  }

  String _fcmTail() {
    final t = _messaging.lastFcmToken;
    if (t == null || t.isEmpty) return '—';
    if (t.length <= 10) return t;
    return '…${t.substring(t.length - 10)}';
  }

  Future<void> _onSendTestPush() async {
    setState(() {
      _sendingTest = true;
      _testResult = null;
    });
    try {
      await _messaging.sendTestPush();
      if (!mounted) return;
      setState(() => _testResult = '✓ Test push requested');
    } catch (e) {
      if (!mounted) return;
      setState(() => _testResult = 'Failed: $e');
    } finally {
      if (mounted) setState(() => _sendingTest = false);
    }
  }
}

class _StatusCard extends StatelessWidget {
  final HubConnectionState state;
  final Set<String> handlers;
  final int dedupSize;
  final String fcmTail;
  final String deviceId;

  const _StatusCard({
    required this.state,
    required this.handlers,
    required this.dedupSize,
    required this.fcmTail,
    required this.deviceId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _stateDot(state),
                const SizedBox(width: 8),
                Text(
                  'Hub: ${_label(state)}',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _kv(theme, 'Registered handlers (${handlers.length})',
                handlers.toList()..sort()),
            const SizedBox(height: 8),
            _kv(theme, 'Dedup cache size', ['$dedupSize / 100']),
            const SizedBox(height: 8),
            _kv(theme, 'FCM token', [fcmTail]),
            const SizedBox(height: 8),
            _kv(theme, 'Device id', [deviceId]),
          ],
        ),
      ),
    );
  }

  Widget _stateDot(HubConnectionState s) {
    Color c;
    switch (s) {
      case HubConnectionState.Connected:
        c = Colors.green;
        break;
      case HubConnectionState.Reconnecting:
      case HubConnectionState.Connecting:
        c = Colors.amber;
        break;
      default:
        c = Colors.red;
    }
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
    );
  }

  String _label(HubConnectionState s) {
    switch (s) {
      case HubConnectionState.Connected:
        return 'Connected';
      case HubConnectionState.Connecting:
        return 'Connecting';
      case HubConnectionState.Reconnecting:
        return 'Reconnecting';
      case HubConnectionState.Disconnected:
        return 'Disconnected';
      case HubConnectionState.Disconnecting:
        return 'Disconnecting';
    }
  }

  Widget _kv(ThemeData theme, String k, List<String> values) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k, style: theme.textTheme.labelSmall),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: values
              .map(
                (v) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    v,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontFamily: 'monospace'),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _LogTile extends StatelessWidget {
  final RealtimeLogEntry entry;
  const _LogTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = entry.isError
        ? theme.colorScheme.error
        : theme.colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 32,
            margin: const EdgeInsets.only(right: 8, top: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_hms(entry.at)}  ${entry.source}  ${entry.name}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: entry.isError
                        ? theme.colorScheme.error
                        : null,
                  ),
                ),
                Text(
                  entry.summary,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontFamily: 'monospace'),
                ),
                if (entry.eventId != null && entry.eventId!.isNotEmpty)
                  Text(
                    'eid=${entry.eventId}',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(fontFamily: 'monospace'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _hms(DateTime t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    final ss = t.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }
}
