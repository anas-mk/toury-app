import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/widgets/custom_card.dart';
import '../cubit/service_areas_cubit.dart';
import '../../domain/entities/service_area_entities.dart';

/// A compact widget for the Helper Dashboard showing service area status.
class ServiceAreaStatusWidget extends StatelessWidget {
  const ServiceAreaStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<ServiceAreasCubit, ServiceAreasState>(
      builder: (context, state) {
        if (state is ServiceAreasLoading || state is ServiceAreaOperationLoading) {
          return const _ShimmerCard();
        }

        final List<ServiceAreaEntity> areas;
        if (state is ServiceAreasLoaded) {
          areas = state.areas;
        } else {
          areas = const [];
        }

        final ServiceAreaEntity? primaryArea = areas.isNotEmpty
            ? (areas.where((a) => a.isPrimary).firstOrNull ?? areas.first)
            : null;

        final isEmpty = areas.isEmpty;

        return GestureDetector(
          onTap: () => context.push('/helper/service-areas'),
          child: CustomCard(
            variant: isEmpty ? CardVariant.outlined : CardVariant.elevated,
            padding: const EdgeInsets.all(AppTheme.spaceMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spaceSM),
                      decoration: BoxDecoration(
                        color: (isEmpty ? AppColor.warningColor : theme.colorScheme.primary).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isEmpty ? Icons.warning_amber_rounded : Icons.map_rounded,
                        color: isEmpty ? AppColor.warningColor : theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceMD),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Service Areas',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            isEmpty
                                ? 'Not visible in scheduled search'
                                : '${areas.length} region${areas.length > 1 ? 's' : ''} configured',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isEmpty ? AppColor.warningColor : (isDark ? AppColor.darkTextSecondary : AppColor.lightTextSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded, 
                      color: isDark ? Colors.white24 : Colors.black26, 
                      size: 14
                    ),
                  ],
                ),
                if (primaryArea != null) ...[
                  const SizedBox(height: AppTheme.spaceMD),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMD, vertical: AppTheme.spaceSM),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.star_rounded, color: theme.colorScheme.primary, size: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${primaryArea.city}, ${primaryArea.country}',
                            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${primaryArea.radiusKm.round()} km',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isDark ? AppColor.darkTextSecondary : AppColor.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (isEmpty) ...[
                  const SizedBox(height: AppTheme.spaceMD),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMD, vertical: AppTheme.spaceSM),
                    decoration: BoxDecoration(
                      color: AppColor.warningColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: AppColor.warningColor, size: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You will not appear in scheduled searches until you add an area.',
                            style: theme.textTheme.labelSmall?.copyWith(color: AppColor.warningColor),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return CustomCard(
      variant: CardVariant.elevated,
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? Colors.white12 : Colors.black12, 
              shape: BoxShape.circle
            ),
          ),
          const SizedBox(width: AppTheme.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(height: 12, width: 120, color: isDark ? Colors.white12 : Colors.black12),
                const SizedBox(height: 6),
                Container(height: 10, width: 80, color: isDark ? Colors.white12 : Colors.black12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
