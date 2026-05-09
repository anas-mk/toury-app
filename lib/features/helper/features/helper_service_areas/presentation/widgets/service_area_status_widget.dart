import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/router/app_router.dart';
import '../../../../../../core/services/haptic_service.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../domain/entities/service_area_entities.dart';
import '../cubit/service_areas_cubit.dart';

/// Modern, theme-aware summary card for the helper dashboard's "Service Area"
/// section. Tapping it opens the full management screen.
class ServiceAreaStatusWidget extends StatelessWidget {
  const ServiceAreaStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ServiceAreasCubit, ServiceAreasState>(
      builder: (context, state) {
        if (state is ServiceAreasLoading ||
            state is ServiceAreaOperationLoading) {
          return const _ShimmerSummaryCard();
        }

        final List<ServiceAreaEntity> areas;
        if (state is ServiceAreasLoaded) {
          areas = state.areas;
        } else {
          areas = const [];
        }

        return _SummaryCard(areas: areas);
      },
    );
  }
}

/// Wrapper that owns its own [ServiceAreasCubit] so the dashboard doesn't
/// need to provide one. Loads areas on first build.
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

// ──────────────────────────────────────────────────────────────────────────────
//  SUMMARY CARD
// ──────────────────────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final List<ServiceAreaEntity> areas;

  const _SummaryCard({required this.areas});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);
    final isEmpty = areas.isEmpty;

    final ServiceAreaEntity? primary = isEmpty
        ? null
        : (areas.where((a) => a.isPrimary).firstOrNull ?? areas.first);

    final accent = isEmpty ? const Color(0xFFFFB020) : palette.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticService.light();
          context.push(AppRouter.helperServiceAreas);
        },
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: palette.border, width: 0.6),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: palette.isDark ? 0.10 : 0.05),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      accent.withValues(alpha: 0.85),
                      accent.withValues(alpha: 0.45),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _IconBadge(
                            icon: isEmpty
                                ? Icons.warning_amber_rounded
                                : Icons.travel_explore_rounded,
                            color: accent,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Service Coverage',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: palette.textPrimary,
                                            letterSpacing: -0.1,
                                          ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (!isEmpty)
                                      _CountPill(
                                        label: '${areas.length}',
                                        color: accent,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isEmpty
                                      ? 'Add an area to be discoverable'
                                      : (areas.length == 1
                                            ? '1 region active'
                                            : '${areas.length} regions active'),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isEmpty
                                        ? accent
                                        : palette.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: palette.textMuted,
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (primary != null)
                        _PrimaryAreaPill(area: primary)
                      else
                        _EmptyHint(accent: accent),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: palette.isDark ? 0.28 : 0.18),
            color.withValues(alpha: palette.isDark ? 0.14 : 0.08),
          ],
        ),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.30), width: 0.8),
      ),
      child: Icon(icon, color: color, size: 19),
    );
  }
}

class _CountPill extends StatelessWidget {
  final String label;
  final Color color;

  const _CountPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: palette.isDark ? 0.28 : 0.16),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: palette.textPrimary,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}

class _PrimaryAreaPill extends StatelessWidget {
  final ServiceAreaEntity area;

  const _PrimaryAreaPill({required this.area});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: palette.surfaceInset,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border, width: 0.6),
      ),
      child: Row(
        children: [
          Icon(
            Icons.place_rounded,
            color: palette.primary,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${area.city}, ${area.country}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: palette.primary.withValues(
                alpha: palette.isDark ? 0.22 : 0.12,
              ),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '${area.radiusKm.round()} km',
              style: theme.textTheme.labelSmall?.copyWith(
                color: palette.primary,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final Color accent;

  const _EmptyHint({required this.accent});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: palette.isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.30), width: 0.6),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: accent, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "You won't appear in scheduled searches yet.",
              style: theme.textTheme.labelSmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  SHIMMER
// ──────────────────────────────────────────────────────────────────────────────

class _ShimmerSummaryCard extends StatefulWidget {
  const _ShimmerSummaryCard();

  @override
  State<_ShimmerSummaryCard> createState() => _ShimmerSummaryCardState();
}

class _ShimmerSummaryCardState extends State<_ShimmerSummaryCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        return Container(
          height: 110,
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: palette.border, width: 0.6),
          ),
          clipBehavior: Clip.antiAlias,
          child: ShaderMask(
            shaderCallback: (rect) {
              return LinearGradient(
                begin: Alignment(-1 + t * 2, 0),
                end: Alignment(t * 2, 0),
                colors: [
                  palette.surface.withValues(alpha: 0),
                  palette.border.withValues(alpha: 0.55),
                  palette.surface.withValues(alpha: 0),
                ],
              ).createShader(rect);
            },
            blendMode: BlendMode.srcOver,
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }
}
