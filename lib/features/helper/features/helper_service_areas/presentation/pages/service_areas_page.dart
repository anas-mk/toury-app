import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/widgets/custom_card.dart';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop(),
          ),
          title: const Text('Service Areas'),
        ),
        body: BlocConsumer<ServiceAreasCubit, ServiceAreasState>(
          listener: (context, state) {
            if (state is ServiceAreaOperationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColor.accentColor,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else if (state is ServiceAreasError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColor.errorColor,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is ServiceAreasLoading) {
              return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
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
          onPressed: () async {
            await context.push('/helper/add-service-area');
            if (mounted) {
              _cubit.loadAreas();
            }
          },
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: isDark ? Colors.black : Colors.white,
          icon: const Icon(Icons.add_location_alt_rounded),
          label: const Text('Add Area', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceXL),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.map_outlined,
                size: 80,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppTheme.spaceLG),
            Text(
              'No service areas yet',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spaceSM),
            Text(
              'You must define at least one area to appear in scheduled booking searches.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColor.darkTextSecondary : AppColor.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAreasList(BuildContext context, List<ServiceAreaEntity> areas) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final ServiceAreaEntity? primaryArea =
        areas.where((a) => a.isPrimary).firstOrNull ?? (areas.isNotEmpty ? areas.first : null);
    
    if (primaryArea == null) return const SizedBox.shrink();

    final otherAreas = areas.where((a) => a.id != primaryArea.id).toList();

    return ListView(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      children: [
        Text(
          'Primary Working Area',
          style: theme.textTheme.labelLarge?.copyWith(
            color: isDark ? AppColor.darkTextSecondary : AppColor.lightTextSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spaceSM),
        _ServiceAreaCard(area: primaryArea, isHero: true),
        const SizedBox(height: AppTheme.spaceXL),
        if (otherAreas.isNotEmpty) ...[
          Text(
            'Other Regions',
            style: theme.textTheme.labelLarge?.copyWith(
              color: isDark ? AppColor.darkTextSecondary : AppColor.lightTextSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSM),
          ...otherAreas.map((area) => Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spaceMD),
                child: _ServiceAreaCard(area: area),
              )),
        ] else if (areas.length == 1)
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceMD),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Colors.orange),
                const SizedBox(width: AppTheme.spaceSM),
                Expanded(
                  child: Text(
                    'Consider adding more areas to increase your visibility to travelers.',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 80), // Fab space
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return CustomCard(
      variant: isHero ? CardVariant.elevated : CardVariant.outlined,
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceSM),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.location_on_rounded, color: theme.colorScheme.primary, size: 24),
              ),
              const SizedBox(width: AppTheme.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      area.city,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${area.areaName ?? "City Center"}, ${area.country}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? AppColor.darkTextSecondary : AppColor.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (area.isPrimary)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColor.accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                    border: Border.all(color: AppColor.accentColor.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, color: AppColor.accentColor, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'PRIMARY',
                        style: TextStyle(color: AppColor.accentColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceLG),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatItem(label: 'Radius', value: '${area.radiusKm.round()} km'),
              _StatItem(label: 'Latitude', value: area.latitude.toStringAsFixed(4)),
              _StatItem(label: 'Longitude', value: area.longitude.toStringAsFixed(4)),
            ],
          ),
          const SizedBox(height: AppTheme.spaceLG),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await context.push('/helper/edit-service-area', extra: area);
                    if (context.mounted) {
                      context.read<ServiceAreasCubit>().loadAreas();
                    }
                  },
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: AppTheme.spaceSM),
              IconButton(
                onPressed: () => _confirmDelete(context),
                icon: const Icon(Icons.delete_outline_rounded, color: AppColor.errorColor),
                style: IconButton.styleFrom(
                  backgroundColor: AppColor.errorColor.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMD)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Area?'),
        content: const Text('Travelers in this region will no longer see you in scheduled searches.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ServiceAreasCubit>().deleteArea(area.id);
            },
            child: const Text('Delete', style: TextStyle(color: AppColor.errorColor)),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isDark ? AppColor.darkTextSecondary : AppColor.lightTextSecondary,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
