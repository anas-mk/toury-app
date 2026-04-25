import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/di/injection_container.dart';
import '../cubit/service_areas_cubit.dart';
import '../../domain/entities/service_area_entities.dart';

/// A compact widget for the Helper Dashboard showing service area status.
class ServiceAreaStatusWidget extends StatelessWidget {
  const ServiceAreaStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ServiceAreasCubit, ServiceAreasState>(
      builder: (context, state) {
        if (state is ServiceAreasLoading || state is ServiceAreaOperationLoading) {
          return const _ShimmerCard();
        }

        // Safely extract the typed entity list — never cast or assume runtime type.
        final List<ServiceAreaEntity> areas;
        if (state is ServiceAreasLoaded) {
          areas = state.areas;
        } else {
          areas = const [];
        }

        // Use null-safe lookup instead of firstWhere to avoid orElse type issues.
        final ServiceAreaEntity? primaryArea = areas.isNotEmpty
            ? (areas.where((a) => a.isPrimary).firstOrNull ?? areas.first)
            : null;

        final isEmpty = areas.isEmpty;

        return GestureDetector(
          onTap: () => context.push('/helper-service-areas'),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F3C),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isEmpty
                    ? Colors.orange.withValues(alpha: 0.3)
                    : const Color(0xFF6C63FF).withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isEmpty ? Colors.orange : const Color(0xFF6C63FF)).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isEmpty ? Icons.warning_amber_rounded : Icons.map_rounded,
                        color: isEmpty ? Colors.orange : const Color(0xFF6C63FF),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Service Areas',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            isEmpty
                                ? 'Not visible in scheduled search'
                                : '${areas.length} region${areas.length > 1 ? 's' : ''} configured',
                            style: TextStyle(
                              color: isEmpty ? Colors.orange : Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
                  ],
                ),
                if (primaryArea != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFF6C63FF), size: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${primaryArea.city}, ${primaryArea.country}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${primaryArea.radiusKm.round()} km',
                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
                if (isEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: Colors.orange, size: 14),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You will not appear in scheduled searches until you add an area.',
                            style: TextStyle(color: Colors.orange, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Cubit provider wrapper — creates and owns its own Cubit instance.
class ServiceAreaStatusCard extends StatefulWidget {
  const ServiceAreaStatusCard({super.key});

  @override
  State<ServiceAreaStatusCard> createState() => _ServiceAreaStatusCardState();
}

class _ServiceAreaStatusCardState extends State<ServiceAreaStatusCard> {
  late final ServiceAreasCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<ServiceAreasCubit>()..loadAreas();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: const ServiceAreaStatusWidget(),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3C),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(color: Colors.white12, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(height: 12, width: 120, color: Colors.white12),
                const SizedBox(height: 6),
                Container(height: 10, width: 80, color: Colors.white12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
