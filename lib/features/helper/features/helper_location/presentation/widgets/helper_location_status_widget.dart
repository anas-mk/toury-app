import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubit/helper_location_cubit.dart';
import '../cubit/location_status_cubits.dart';
import '../../data/services/helper_location_signalr_service.dart';

class HelperLocationStatusWidget extends StatelessWidget {
  const HelperLocationStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocationStatusCubit, LocationStatusState>(
      builder: (context, statusState) {
        return BlocBuilder<HelperLocationCubit, HelperLocationState>(
          builder: (context, locState) {
            bool isTracking = locState is HelperLocationTracking;
            bool isConnected = false;
            bool isEligible = false;
            int secondsSinceUpdate = 0;

            if (locState is HelperLocationTracking) {
              isConnected = locState.connectionState == SignalRConnectionState.connected;
            }
            if (statusState is LocationStatusLoaded) {
              isEligible = statusState.status.isFresh;
              secondsSinceUpdate = statusState.status.secondsSinceLastUpdate;
            }

            return GestureDetector(
              onTap: () => context.push('/helper-location'),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1F3C),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isConnected ? const Color(0xFF00C896).withOpacity(0.2) : Colors.white12,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: (isConnected ? const Color(0xFF00C896) : Colors.white24).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isConnected ? Icons.location_on_rounded : Icons.location_off_rounded,
                        color: isConnected ? const Color(0xFF00C896) : Colors.white38,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                isConnected ? 'Live Tracking' : 'Tracking Offline',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isConnected ? const Color(0xFF00C896) : Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isTracking ? 'Last sync: $secondsSinceUpdate s ago' : 'Tap to start tracking',
                            style: const TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isEligible ? const Color(0xFF00C896) : Colors.orange).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isEligible ? 'ELIGIBLE' : 'STALE',
                        style: TextStyle(
                          color: isEligible ? const Color(0xFF00C896) : Colors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
