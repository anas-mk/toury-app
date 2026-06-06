import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/router/app_router.dart';
import '../../../../../../core/services/haptic_service.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_dimens.dart';
import '../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../core/theme/brand_typography.dart';
import '../../../../../../core/widgets/animations/fade_in_slide.dart';
import '../../../../../../core/widgets/app_dialog.dart';
import '../../../../../../core/widgets/app_empty_state.dart';
import '../../../../../../core/widgets/app_loading.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/service_area_entities.dart';
import '../cubit/service_areas_cubit.dart';

class ServiceAreasPage extends StatefulWidget {
  const ServiceAreasPage({super.key});

  @override
  State<ServiceAreasPage> createState() => _ServiceAreasPageState();
}

class _ServiceAreasPageState extends State<ServiceAreasPage> {
  late final ServiceAreasCubit _cubit;
  List<ServiceAreaEntity> _cachedAreas = const [];
  bool _hasLoadedOnce = false;

  static const _fabClearance = 88.0;

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

  Future<void> _openAdd() async {
    HapticService.light();
    await context.push(AppRouter.helperAddServiceArea);
    if (mounted) _cubit.loadAreas();
  }

  Future<void> _openEdit(ServiceAreaEntity area) async {
    HapticService.light();
    await context.push(AppRouter.helperEditServiceArea, extra: area);
    if (mounted) _cubit.loadAreas();
  }

  void _cacheState(ServiceAreasState state) {
    if (state is ServiceAreasLoaded) {
      _cachedAreas = state.areas;
      _hasLoadedOnce = true;
    } else if (state is ServiceAreasEmpty) {
      _cachedAreas = const [];
      _hasLoadedOnce = true;
    }
  }

  List<ServiceAreaEntity> _sortedAreas(List<ServiceAreaEntity> areas) {
    final sorted = List<ServiceAreaEntity>.from(areas);
    sorted.sort((a, b) {
      if (a.isPrimary != b.isPrimary) return a.isPrimary ? -1 : 1;
      return a.city.compareTo(b.city);
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<ServiceAreasCubit, ServiceAreasState>(
        listener: (context, state) {
          if (state is ServiceAreaOperationSuccess) {
            AppSnackbar.show(
              context,
              message: state.message,
              tone: AppSnackTone.success,
            );
          } else if (state is ServiceAreasError) {
            AppSnackbar.show(
              context,
              message: state.message,
              tone: AppSnackTone.danger,
            );
          }
        },
        builder: (context, state) {
          _cacheState(state);
          final palette = AppColors.of(context);
          final theme = Theme.of(context);
          final areas = _sortedAreas(_cachedAreas);
          final showInitialSpinner =
              state is ServiceAreasLoading && !_hasLoadedOnce;

          return AppScaffold(
            backgroundColor: palette.scaffold,
            floatingActionButton: showInitialSpinner
                ? null
                : Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: FloatingActionButton.extended(
                      onPressed: _openAdd,
                      elevation: 6,
                      highlightElevation: 10,
                      backgroundColor: palette.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      icon: const Icon(Icons.add_location_alt_rounded, size: 20),
                      label: Text(
                        'Add region',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.endFloat,
            body: RefreshIndicator.adaptive(
              onRefresh: () async => _cubit.loadAreas(),
              color: palette.primary,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverAppBar(
                    backgroundColor: palette.scaffold,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    pinned: true,
                    automaticallyImplyLeading: false,
                    leading: Navigator.of(context).canPop()
                        ? IconButton(
                            onPressed: () {
                              HapticService.light();
                              context.pop();
                            },
                            icon: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: palette.textPrimary,
                              size: 18,
                            ),
                          )
                        : null,
                    title: Text(
                      'Regions',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                      ),
                    ),
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(44),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.pageGutter,
                          0,
                          AppSpacing.pageGutter,
                          AppSpacing.md,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            areas.isEmpty
                                ? 'Add service areas so travelers can find you'
                                : '${areas.length} active region${areas.length == 1 ? '' : 's'}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: palette.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (showInitialSpinner)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: AppLoading(fullScreen: false)),
                    )
                  else if (areas.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.pageGutter,
                          0,
                          AppSpacing.pageGutter,
                          _fabClearance,
                        ),
                        child: Center(
                          child: AppEmptyState(
                            icon: Icons.travel_explore_rounded,
                            title: 'No regions yet',
                            message:
                                'Tap Add region to pin your first coverage area on the map.',
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.xl,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.pageGutter,
                        AppSpacing.sm,
                        AppSpacing.pageGutter,
                        _fabClearance,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index == areas.length) {
                              if (areas.length != 1) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.md,
                                ),
                                child: const _MultiRegionHint(),
                              );
                            }

                            final area = areas[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index == areas.length - 1 &&
                                        areas.length == 1
                                    ? AppSpacing.md
                                    : AppSpacing.md,
                              ),
                              child: FadeInSlide(
                                delay: Duration(
                                  milliseconds: (index * 50).clamp(0, 240),
                                ),
                                child: _RegionCard(
                                  area: area,
                                  onEdit: () => _openEdit(area),
                                  onDelete: () => _confirmDelete(context, area),
                                ),
                              ),
                            );
                          },
                          childCount: areas.length + (areas.length == 1 ? 1 : 0),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ServiceAreaEntity area,
  ) async {
    HapticService.light();
    final confirmed = await AppDialog.confirm(
      context: context,
      title: 'Remove this region?',
      message:
          'Travelers in ${area.city} will no longer see you in scheduled searches.',
      confirmLabel: 'Remove',
      cancelLabel: 'Cancel',
      tone: AppDialogTone.danger,
      icon: Icons.delete_outline_rounded,
    );
    if (confirmed && context.mounted) {
      HapticFeedback.mediumImpact();
      context.read<ServiceAreasCubit>().deleteArea(area.id);
    }
  }
}

// ─── Region Card ─────────────────────────────────────────────────────────────

class _RegionCard extends StatelessWidget {
  final ServiceAreaEntity area;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RegionCard({
    required this.area,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);
    final cityLabel = area.city.isNotEmpty ? area.city : '—';
    final subtitle = [
      if ((area.areaName ?? '').isNotEmpty) area.areaName!,
      area.country,
    ].join(' · ');
    final isPrimary = area.isPrimary;
    final accent = isPrimary ? BrandTokens.accentAmber : palette.primary;

    return Material(
      color: palette.surfaceElevated,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: isPrimary
                  ? BrandTokens.accentAmber.withValues(alpha: 0.35)
                  : palette.border,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: palette.isDark ? 0.18 : 0.04,
                ),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _CityBadge(label: _cityInitials(cityLabel), accent: accent),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cityLabel,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          subtitle,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: palette.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: [
                          _StatusPill(area: area),
                          _MetaChip(
                            icon: Icons.radar_rounded,
                            label: '${area.radiusKm.round()} km radius',
                            color: palette.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: palette.danger,
                    size: 20,
                  ),
                  tooltip: 'Remove region',
                  style: IconButton.styleFrom(
                    minimumSize: const Size(36, 36),
                    padding: EdgeInsets.zero,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: palette.textMuted,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _cityInitials(String city) {
    final parts = city.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }
}

class _CityBadge extends StatelessWidget {
  final String label;
  final Color accent;

  const _CityBadge({required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.22),
            accent.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Center(
        child: Text(
          label,
          style: BrandTypography.title(
            weight: FontWeight.w800,
          ).copyWith(fontSize: 13, color: accent, letterSpacing: 0.4),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final ServiceAreaEntity area;

  const _StatusPill({required this.area});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);
    final isPrimary = area.isPrimary;
    final color =
        isPrimary ? BrandTokens.accentAmber : palette.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + AppSpacing.xs,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPrimary ? Icons.star_rounded : Icons.place_outlined,
            size: 12,
            color: color,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            isPrimary ? 'Primary' : 'Secondary',
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + AppSpacing.xs,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceInset,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: palette.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MultiRegionHint extends StatelessWidget {
  const _MultiRegionHint();

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);
    const accent = BrandTokens.accentAmber;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded, color: accent, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Want more bookings?',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Helpers with multiple regions get up to 3× more requests.',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: palette.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
