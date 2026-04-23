import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:signalr_netcore/hub_connection.dart';
import '../cubit/helper_location_cubit.dart';
import '../widgets/status_panel_widget.dart';
import '../widgets/debug_eligibility_widget.dart';

class LocationTrackingScreen extends StatefulWidget {
  const LocationTrackingScreen({super.key});

  @override
  State<LocationTrackingScreen> createState() => _LocationTrackingScreenState();
}

class _LocationTrackingScreenState extends State<LocationTrackingScreen> {
  @override
  void initState() {
    super.initState();
    context.read<HelperLocationCubit>().startTracking();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Location & Eligibility'),
        actions: [
          BlocBuilder<HelperLocationCubit, HelperLocationState>(
            builder: (context, state) {
              if (state is LocationTracking) {
                return IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    context.read<HelperLocationCubit>().refreshStatus();
                    context.read<HelperLocationCubit>().refreshEligibility();
                  },
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
      body: BlocConsumer<HelperLocationCubit, HelperLocationState>(
        listener: (context, state) {
          if (state is LocationError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is LocationInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is LocationTracking) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusPanelWidget(
                    status: state.status,
                    isOnline: state.connectionState == HubConnectionState.Connected,
                  ),
                  const SizedBox(height: 20),
                  _buildLocationDetails(state),
                  const SizedBox(height: 24),
                  DebugEligibilityWidget(
                    eligibility: state.eligibility,
                    isLoading: state.isUpdating,
                    onRefresh: () => context.read<HelperLocationCubit>().refreshEligibility(),
                  ),
                  const SizedBox(height: 32),
                  _buildTrackingIndicator(state),
                ],
              ),
            );
          }

          if (state is LocationError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<HelperLocationCubit>().startTracking(),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildLocationDetails(LocationTracking state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Current Coordinates', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          if (state.lastPosition != null)
            Row(
              children: [
                _buildCoord('Lat', state.lastPosition!.latitude.toStringAsFixed(6)),
                const SizedBox(width: 24),
                _buildCoord('Long', state.lastPosition!.longitude.toStringAsFixed(6)),
              ],
            )
          else
            const Text('Waiting for GPS...', style: TextStyle(fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildCoord(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
      ],
    );
  }

  Widget _buildTrackingIndicator(LocationTracking state) {
    return Center(
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(
                'Live tracking active',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.read<HelperLocationCubit>().stopTracking(),
            child: const Text('Stop Tracking', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
