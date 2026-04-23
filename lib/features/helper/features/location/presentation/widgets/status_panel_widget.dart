import 'package:flutter/material.dart';
import '../../data/models/location_models.dart';

class StatusPanelWidget extends StatelessWidget {
  final HelperLocationStatus? status;
  final bool isOnline;

  const StatusPanelWidget({super.key, this.status, required this.isOnline});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Availability', style: theme.textTheme.bodySmall),
                    Text(
                      status?.availabilityState ?? 'Unknown',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getStateColor(status?.availabilityState),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isOnline ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 4, backgroundColor: isOnline ? Colors.green : Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        isOnline ? 'Real-time' : 'Fallback Mode',
                        style: TextStyle(color: isOnline ? Colors.green : Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                _buildInfoItem(context, Icons.timer_outlined, 'Freshness', status?.freshness ?? 'N/A'),
                const Spacer(),
                _buildInfoItem(
                  context,
                  Icons.bolt,
                  'Instant Requests',
                  status?.canReceiveInstantRequests == true ? 'ELIGIBLE' : 'INELIGIBLE',
                  color: status?.canReceiveInstantRequests == true ? Colors.blue : Colors.orange,
                ),
              ],
            ),
            if (status?.warnings.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              ...status!.warnings.map((w) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(w, style: const TextStyle(color: Colors.orange, fontSize: 12))),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String label, String value, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ],
    );
  }

  Color _getStateColor(String? state) {
    switch (state) {
      case 'AvailableNow': return Colors.green;
      case 'Busy': return Colors.orange;
      case 'Offline': return Colors.grey;
      default: return Colors.grey;
    }
  }
}
