import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/router/app_router.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../core/theme/brand_typography.dart';
import '../../../../../../core/widgets/animations/fade_in_slide.dart';
import '../../../../../../core/widgets/app_dialog.dart';
import '../../../../../../core/widgets/app_empty_state.dart';
import '../../../../../../core/widgets/app_loading.dart';
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
    HapticFeedback.selectionClick();
    await context.push(AppRouter.helperAddServiceArea);
    if (mounted) _cubit.loadAreas();
  }

  Future<void> _openEdit(ServiceAreaEntity area) async {
    HapticFeedback.selectionClick();
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
      child: Scaffold(
        backgroundColor: BrandTokens.bgSoft,
        body: BlocConsumer<ServiceAreasCubit, ServiceAreasState>(
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
            final areas = _sortedAreas(_cachedAreas);
            final showInitialSpinner =
                state is ServiceAreasLoading && !_hasLoadedOnce;
            final hasPrimary = areas.any((a) => a.isPrimary);
            final totalRadiusKm = areas.fold<double>(
              0,
              (sum, area) => sum + area.radiusKm,
            );

            return RefreshIndicator.adaptive(
              onRefresh: () async => _cubit.loadAreas(),
              color: BrandTokens.primaryBlue,
              backgroundColor: Colors.white,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  const SliverToBoxAdapter(
                    child: _PageHeader(title: 'Regions'),
                  ),
                  if (!showInitialSpinner && areas.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _StatsStrip(
                        count: areas.length,
                        hasPrimary: hasPrimary,
                        totalRadiusKm: totalRadiusKm.round(),
                      ),
                    ),
                  if (showInitialSpinner)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: AppSpinner.large()),
                    )
                  else if (areas.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: AppEmptyState(
                          icon: Icons.travel_explore_rounded,
                          title: 'No regions yet',
                          message:
                              'Add at least one service area so travelers can find you in scheduled searches.',
                          actionLabel: 'Add your first region',
                          onAction: _openAdd,
                        ),
                      ),
                    )
                  else ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: _AddRegionButton(onPressed: _openAdd),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      sliver: SliverList.separated(
                        itemCount: areas.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final area = areas[index];
                          return FadeInSlide(
                            delay: Duration(milliseconds: 50 * index),
                            child: _RegionCard(
                              area: area,
                              onEdit: () => _openEdit(area),
                              onDelete: () => _confirmDelete(context, area),
                            ),
                          );
                        },
                      ),
                    ),
                    if (areas.length == 1)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
                          child: _MultiRegionHint(),
                        ),
                      ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ServiceAreaEntity area,
  ) async {
    HapticFeedback.selectionClick();
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

// ─── Page Header ─────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  final String title;

  const _PageHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final canPop = Navigator.of(context).canPop();

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
        child: SizedBox(
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (canPop)
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      context.pop();
                    },
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: palette.textPrimary,
                      size: 20,
                    ),
                    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  ),
                ),
              Text(
                title,
                textAlign: TextAlign.center,
                style: BrandTypography.title(
                  weight: FontWeight.w800,
                ).copyWith(fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Stats Strip ─────────────────────────────────────────────────────────────

class _StatsStrip extends StatelessWidget {
  final int count;
  final bool hasPrimary;
  final int totalRadiusKm;

  const _StatsStrip({
    required this.count,
    required this.hasPrimary,
    required this.totalRadiusKm,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _StatTile(
              icon: Icons.map_rounded,
              label: 'Regions',
              value: '$count',
              color: BrandTokens.primaryBlue,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatTile(
              icon: Icons.star_rounded,
              label: 'Primary',
              value: hasPrimary ? 'Set' : 'None',
              color: const Color(0xFFFFB020),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatTile(
              icon: Icons.radar_rounded,
              label: 'Coverage',
              value: '${totalRadiusKm}km',
              color: const Color(0xFF6366F1),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: BrandTokens.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BrandTokens.borderSoft),
        boxShadow: BrandTokens.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: BrandTypography.title(
                    weight: FontWeight.w800,
                  ).copyWith(fontSize: 15, height: 1),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: BrandTypography.overline(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Add Button ──────────────────────────────────────────────────────────────

class _AddRegionButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AddRegionButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BrandTokens.surfaceWhite,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: BrandTokens.borderSoft),
            boxShadow: BrandTokens.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: BrandTokens.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.add_location_alt_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Add region',
                  style: BrandTypography.body(weight: FontWeight.w600),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: BrandTokens.textMuted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
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
    final cityLabel = area.city.isNotEmpty ? area.city : '—';
    final subtitle = [
      if ((area.areaName ?? '').isNotEmpty) area.areaName!,
      area.country,
    ].join(' · ');

    return Material(
      color: BrandTokens.surfaceWhite,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: area.isPrimary
                  ? const Color(0xFFFFB020).withValues(alpha: 0.35)
                  : BrandTokens.borderSoft,
            ),
            boxShadow: BrandTokens.cardShadow,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CityBadge(label: _cityInitials(cityLabel)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cityLabel,
                          style: BrandTypography.title(
                            weight: FontWeight.w800,
                          ).copyWith(fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle.isEmpty ? '—' : subtitle,
                          style: BrandTypography.caption(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: BrandTokens.dangerSos,
                      size: 20,
                    ),
                    tooltip: 'Remove region',
                    style: IconButton.styleFrom(
                      minimumSize: const Size(36, 36),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _StatusPill(area: area),
                  const SizedBox(width: 8),
                  _MetaChip(
                    icon: Icons.radio_button_checked_rounded,
                    label: '${area.radiusKm.round()} km',
                    color: BrandTokens.primaryBlue,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit region'),
                  style: TextButton.styleFrom(
                    foregroundColor: BrandTokens.primaryBlue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
            ],
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

  const _CityBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFB020).withValues(alpha: 0.18),
            BrandTokens.primaryBlue.withValues(alpha: 0.14),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFFB020).withValues(alpha: 0.22),
          width: 0.6,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: BrandTokens.heading(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: BrandTokens.primaryBlue,
            letterSpacing: 0.6,
          ),
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
    final IconData icon;
    final String label;
    final Color color;

    if (area.isPrimary) {
      icon = Icons.star_rounded;
      label = 'Primary';
      color = const Color(0xFFFFB020);
    } else {
      icon = Icons.place_outlined;
      label = 'Secondary';
      color = BrandTokens.textMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: BrandTokens.bgSoft,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: BrandTokens.borderSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: BrandTypography.caption(
              color: BrandTokens.textPrimary,
              weight: FontWeight.w600,
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
    const accent = Color(0xFFFFB020);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline_rounded, color: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Want more bookings?',
                  style: BrandTypography.body(weight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'Helpers with multiple regions get up to 3× more requests.',
                  style: BrandTypography.caption(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
