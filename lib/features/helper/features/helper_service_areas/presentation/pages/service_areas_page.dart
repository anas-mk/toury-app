import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/di/injection_container.dart';
import '../cubit/service_areas_cubit.dart';
import '../../domain/entities/service_area_entities.dart';

class ServiceAreasPage extends StatefulWidget {
  const ServiceAreasPage({super.key});

  @override
  State<ServiceAreasPage> createState() => _ServiceAreasPageState();
}

class _ServiceAreasPageState extends State<ServiceAreasPage> {
  late final ServiceAreasCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<ServiceAreasCubit>();
    _cubit.loadAreas();
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
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0E1A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          title: const Text('Service Areas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: BlocConsumer<ServiceAreasCubit, ServiceAreasState>(
          listener: (context, state) {
            if (state is ServiceAreaOperationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: const Color(0xFF00C896)),
              );
            } else if (state is ServiceAreasError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: const Color(0xFFFF6B6B)),
              );
            }
          },
          builder: (context, state) {
            if (state is ServiceAreasLoading) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
            }

            if (state is ServiceAreasEmpty) {
              return _buildEmptyState(context);
            }

            if (state is ServiceAreasLoaded) {
              return _buildAreasList(context, state.areas);
            }

            return const SizedBox.shrink();
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/helper-add-service-area'),
          backgroundColor: const Color(0xFF6C63FF),
          icon: const Icon(Icons.add_location_alt_rounded),
          label: const Text('Add Area', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.map_outlined, size: 80, color: Color(0xFF6C63FF)),
            ),
            const SizedBox(height: 24),
            const Text(
              'No service areas yet',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'You must define at least one area to appear in scheduled booking searches.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAreasList(BuildContext context, List<ServiceAreaEntity> areas) {
    // Null-safe primary lookup — avoids firstWhere orElse type mismatch.
    final ServiceAreaEntity primaryArea =
        areas.where((a) => a.isPrimary).firstOrNull ?? areas.first;
    final otherAreas = areas.where((a) => a.id != primaryArea.id).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Primary Working Area',
          style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        _ServiceAreaCard(area: primaryArea, isHero: true),
        const SizedBox(height: 30),
        if (otherAreas.isNotEmpty) ...[
          const Text(
            'Other Regions',
            style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...otherAreas.map((area) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _ServiceAreaCard(area: area),
              )),
        ] else if (areas.length == 1)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange.withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Colors.orange),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Consider adding more areas to increase your visibility to travelers.',
                    style: TextStyle(color: Colors.orange, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ServiceAreaCard extends StatelessWidget {
  final ServiceAreaEntity area;
  final bool isHero;

  const _ServiceAreaCard({required this.area, this.isHero = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3C).withValues(alpha: isHero ? 1.0 : 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isHero ? const Color(0xFF6C63FF).withOpacity(0.5) : Colors.white.withOpacity(0.05),
          width: isHero ? 2 : 1,
        ),
        boxShadow: isHero
            ? [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push('/helper-edit-service-area', extra: area),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on_rounded, color: Color(0xFF6C63FF), size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              area.city,
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${area.areaName ?? "City Center"}, ${area.country}',
                              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      if (area.isPrimary)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFF928DFF)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_rounded, color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text('PRIMARY',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatItem(label: 'Radius', value: '${area.radiusKm.round()} km'),
                      _StatItem(label: 'Latitude', value: area.latitude.toStringAsFixed(4)),
                      _StatItem(label: 'Longitude', value: area.longitude.toStringAsFixed(4)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/helper-edit-service-area', extra: area),
                          icon: const Icon(Icons.edit_rounded, size: 16),
                          label: const Text('Edit'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: BorderSide(color: Colors.white.withOpacity(0.1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () => _confirmDelete(context),
                        icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF6B6B)),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B6B).withOpacity(0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3C),
        title: const Text('Delete Area?', style: TextStyle(color: Colors.white)),
        content: const Text('Travelers in this region will no longer see you in scheduled searches.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ServiceAreasCubit>().deleteArea(area.id);
            },
            child: const Text('Delete', style: TextStyle(color: Color(0xFFFF6B6B))),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
