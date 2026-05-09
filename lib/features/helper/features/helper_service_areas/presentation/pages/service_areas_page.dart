import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/router/app_router.dart';
import '../../../../../../core/services/haptic_service.dart';
import '../../../../../../core/theme/app_color.dart';
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

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: palette.scaffold,
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
            final areas = _cachedAreas;
            final showInitialSpinner =
                state is ServiceAreasLoading && !_hasLoadedOnce;

            return RefreshIndicator(
              onRefresh: () async => _cubit.loadAreas(),
              color: palette.primary,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  _SliverHero(
                    count: areas.length,
                    isPrimary: areas.any((a) => a.isPrimary),
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
                          title: 'No service areas yet',
                          message:
                              'Add at least one region to be discoverable in scheduled traveler searches.',
                          actionLabel: 'Add your first area',
                          onAction: _openAdd,
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                      sliver: _AreasSliver(
                        areas: areas,
                        onEdit: _openEdit,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        floatingActionButton: BlocBuilder<ServiceAreasCubit, ServiceAreasState>(
          builder: (context, state) {
            if (_cachedAreas.isEmpty) return const SizedBox.shrink();
            return _AddFab(onPressed: _openAdd);
          },
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  SLIVER HERO
// ──────────────────────────────────────────────────────────────────────────────

class _SliverHero extends StatelessWidget {
  final int count;
  final bool isPrimary;

  const _SliverHero({required this.count, required this.isPrimary});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);

    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: 200,
      backgroundColor: palette.scaffold,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: palette.textPrimary),
        onPressed: () {
          HapticService.light();
          context.pop();
        },
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(56, 0, 20, 14),
        title: Text(
          'Service Coverage',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        background: _HeroBackground(count: count, isPrimary: isPrimary),
      ),
    );
  }
}

class _HeroBackground extends StatelessWidget {
  final int count;
  final bool isPrimary;

  const _HeroBackground({required this.count, required this.isPrimary});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);
    final c1 = palette.primary;
    final c2 = const Color(0xFF7B61FF);

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  c1.withValues(alpha: palette.isDark ? 0.30 : 0.18),
                  c2.withValues(alpha: palette.isDark ? 0.18 : 0.10),
                  palette.scaffold,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          top: -40,
          right: -30,
          child: _Orb(color: c1, size: 180),
        ),
        Positioned(
          bottom: -30,
          left: -50,
          child: _Orb(color: c2, size: 140),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          c1.withValues(alpha: 0.25),
                          c1.withValues(alpha: 0.12),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: c1.withValues(alpha: 0.30),
                        width: 0.8,
                      ),
                    ),
                    child: Icon(
                      Icons.travel_explore_rounded,
                      color: c1,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _StatPill(
                    label: count == 0
                        ? 'No regions'
                        : '$count region${count == 1 ? '' : 's'}',
                    color: count == 0 ? const Color(0xFFFFB020) : c1,
                  ),
                  const SizedBox(width: 8),
                  if (count > 0)
                    _StatPill(
                      label: isPrimary ? 'Primary set' : 'No primary',
                      color: isPrimary ? palette.success : const Color(0xFFFFB020),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Tell travelers where you operate',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Orb extends StatelessWidget {
  final Color color;
  final double size;

  const _Orb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.30),
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: palette.isDark ? 0.22 : 0.14),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.30), width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: palette.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  AREAS SLIVER
// ──────────────────────────────────────────────────────────────────────────────

class _AreasSliver extends StatelessWidget {
  final List<ServiceAreaEntity> areas;
  final void Function(ServiceAreaEntity area) onEdit;

  const _AreasSliver({required this.areas, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final ServiceAreaEntity primary =
        areas.where((a) => a.isPrimary).firstOrNull ?? areas.first;
    final others = areas.where((a) => a.id != primary.id).toList();

    final children = <Widget>[
      const SizedBox(height: 10),
      const _SectionHeading(label: 'Primary Region'),
      const SizedBox(height: 10),
      FadeInSlide(
        child: _AreaCard(area: primary, isHero: true, onEdit: () => onEdit(primary)),
      ),
      const SizedBox(height: 24),
      if (others.isNotEmpty) ...[
        _SectionHeading(label: 'Other Regions (${others.length})'),
        const SizedBox(height: 10),
        for (var i = 0; i < others.length; i++) ...[
          FadeInSlide(
            delay: Duration(milliseconds: 60 * i),
            child: _AreaCard(area: others[i], onEdit: () => onEdit(others[i])),
          ),
          const SizedBox(height: 12),
        ],
      ] else ...[
        const _SoloRegionHint(),
      ],
    ];

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) => children[i],
        childCount: children.length,
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String label;
  const _SectionHeading({required this.label});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: palette.textMuted,
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SoloRegionHint extends StatelessWidget {
  const _SoloRegionHint();

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);
    const accent = Color(0xFFFFB020);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: palette.isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.30)),
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
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Helpers with multiple regions get up to 3× more requests.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.textSecondary,
                    height: 1.4,
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

// ──────────────────────────────────────────────────────────────────────────────
//  AREA CARD
// ──────────────────────────────────────────────────────────────────────────────

class _AreaCard extends StatelessWidget {
  final ServiceAreaEntity area;
  final bool isHero;
  final VoidCallback onEdit;

  const _AreaCard({
    required this.area,
    required this.onEdit,
    this.isHero = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);

    final accent = isHero ? const Color(0xFFFFB020) : palette.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isHero
                  ? accent.withValues(alpha: 0.35)
                  : palette.border,
              width: isHero ? 1.0 : 0.6,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: palette.isDark ? 0.12 : 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AreaIcon(color: accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                area.city.isNotEmpty ? area.city : '—',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: palette.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            if (area.isPrimary) const _PrimaryBadge(),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            if ((area.areaName ?? '').isNotEmpty) area.areaName!,
                            area.country,
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _MetaChip(
                    icon: Icons.radio_button_checked_rounded,
                    label: '${area.radiusKm.round()} km radius',
                    color: accent,
                  ),
                  const SizedBox(width: 8),
                  _MetaChip(
                    icon: Icons.my_location_rounded,
                    label:
                        '${area.latitude.toStringAsFixed(2)}, ${area.longitude.toStringAsFixed(2)}',
                    color: palette.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: palette.textPrimary,
                        side: BorderSide(color: palette.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _confirmDelete(context),
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: palette.danger,
                      size: 20,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: palette.danger.withValues(
                        alpha: palette.isDark ? 0.18 : 0.10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(10),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
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
      HapticService.medium();
      context.read<ServiceAreasCubit>().deleteArea(area.id);
    }
  }
}

class _AreaIcon extends StatelessWidget {
  final Color color;

  const _AreaIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: palette.isDark ? 0.28 : 0.18),
            color.withValues(alpha: palette.isDark ? 0.14 : 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.30), width: 0.8),
      ),
      child: Icon(Icons.place_rounded, color: color, size: 22),
    );
  }
}

class _PrimaryBadge extends StatelessWidget {
  const _PrimaryBadge();

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    const accent = Color(0xFFFFB020);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: palette.isDark ? 0.30 : 0.18),
            accent.withValues(alpha: palette.isDark ? 0.18 : 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: accent.withValues(alpha: 0.40)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: accent, size: 12),
          SizedBox(width: 4),
          Text(
            'PRIMARY',
            style: TextStyle(
              color: accent,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
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
    final palette = AppColors.of(context);
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: palette.surfaceInset,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: palette.border, width: 0.6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  ADD FAB
// ──────────────────────────────────────────────────────────────────────────────

class _AddFab extends StatelessWidget {
  final VoidCallback onPressed;
  const _AddFab({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.primary,
            const Color(0xFF7B61FF),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: palette.primary.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(99),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.add_location_alt_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Add Region',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
