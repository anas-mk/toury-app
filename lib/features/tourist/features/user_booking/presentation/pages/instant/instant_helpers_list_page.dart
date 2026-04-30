import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../../core/router/app_router.dart';
import '../../../../../../../core/theme/app_theme.dart';
import '../../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../../core/theme/brand_typography.dart';
import '../../../../../../../core/widgets/hero_header.dart';
import '../../../domain/entities/helper_search_result.dart';
import '../../../domain/entities/instant_search_request.dart';
import '../../cubits/instant_booking_cubit.dart';
import '../../cubits/instant_booking_state.dart';
import '../../widgets/instant/empty_error_state.dart';
import '../../widgets/instant/helper_suitability_card.dart';
import '../../widgets/instant/skeleton.dart';
import 'location_pick_result.dart';

/// Step 4 — list of helpers returned from `POST /user/bookings/instant/search`.
class InstantHelpersListPage extends StatelessWidget {
  final InstantBookingCubit cubit;
  final InstantSearchRequest searchRequest;
  final LocationPickResult pickup;
  final LocationPickResult destination;
  final int travelers;
  final int durationInMinutes;
  final String? languageCode;
  final bool requiresCar;
  final String? notes;

  const InstantHelpersListPage({
    super.key,
    required this.cubit,
    required this.searchRequest,
    required this.pickup,
    required this.destination,
    required this.travelers,
    required this.durationInMinutes,
    required this.languageCode,
    required this.requiresCar,
    required this.notes,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: _HelpersListView(
        searchRequest: searchRequest,
        pickup: pickup,
        destination: destination,
        travelers: travelers,
        durationInMinutes: durationInMinutes,
        languageCode: languageCode,
        requiresCar: requiresCar,
        notes: notes,
      ),
    );
  }
}

class _HelpersListView extends StatelessWidget {
  final InstantSearchRequest searchRequest;
  final LocationPickResult pickup;
  final LocationPickResult destination;
  final int travelers;
  final int durationInMinutes;
  final String? languageCode;
  final bool requiresCar;
  final String? notes;

  const _HelpersListView({
    required this.searchRequest,
    required this.pickup,
    required this.destination,
    required this.travelers,
    required this.durationInMinutes,
    required this.languageCode,
    required this.requiresCar,
    required this.notes,
  });

  void _onTap(BuildContext context, HelperSearchResult helper) {
    context.push(
      AppRouter.instantHelperProfile.replaceFirst(':id', helper.helperId),
      extra: {
        'cubit': context.read<InstantBookingCubit>(),
        'helper': helper,
        'pickup': pickup,
        'destination': destination,
        'travelers': travelers,
        'durationInMinutes': durationInMinutes,
        'languageCode': languageCode,
        'requiresCar': requiresCar,
        'notes': notes,
      },
    );
  }

  void _retry(BuildContext context) {
    context.read<InstantBookingCubit>().searchHelpers(searchRequest);
  }

  HeroSliverHeader _buildHeader({required int count, required bool isLoading}) {
    return HeroSliverHeader(
      title: isLoading ? 'Finding your helper' : 'Pick your helper',
      subtitle: isLoading
          ? 'Ranking nearby helpers by trust, distance, language and price.'
          : '$count match${count == 1 ? '' : 'es'} ready for your trip',
      leadingIcon: Icons.travel_explore_rounded,
      height: 240,
      trailing: _MatchCountBadge(count: count, isLoading: isLoading),
      footer: _TripSummaryPills(
        pickupName: pickup.name,
        destinationName: destination.name,
        durationInMinutes: durationInMinutes,
        travelers: travelers,
        requiresCar: requiresCar,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandTokens.bgSoft,
      extendBodyBehindAppBar: true,
      body: BlocBuilder<InstantBookingCubit, InstantBookingState>(
        builder: (context, state) {
          if (state is InstantBookingError) {
            return CustomScrollView(
              slivers: [
                SliverPersistentHeader(
                  pinned: false,
                  delegate: _buildHeader(count: 0, isLoading: false),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorRetryState(
                    message: state.message,
                    onRetry: () => _retry(context),
                  ),
                ),
              ],
            );
          }

          if (state is InstantBookingHelpersLoaded) {
            if (state.helpers.isEmpty) {
              return CustomScrollView(
                slivers: [
                  SliverPersistentHeader(
                    pinned: false,
                    delegate: _buildHeader(count: 0, isLoading: false),
                  ),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No helpers nearby',
                      message:
                          'Try widening duration, lowering travelers count, or removing the car requirement.',
                      actionLabel: 'Edit search',
                      onAction: () => context.pop(),
                    ),
                  ),
                ],
              );
            }
            return RefreshIndicator(
              onRefresh: () async => _retry(context),
              child: CustomScrollView(
                slivers: [
                  SliverPersistentHeader(
                    pinned: false,
                    delegate: _buildHeader(
                      count: state.helpers.length,
                      isLoading: false,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.spaceLG,
                        AppTheme.spaceLG,
                        AppTheme.spaceLG,
                        AppTheme.spaceLG,
                      ),
                      child: _HelpersRevealPanel(
                        helpers: state.helpers,
                        onTap: (h) => _onTap(context, h),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // Searching / Initial / other states -> loading skeletons
          return CustomScrollView(
            slivers: [
              SliverPersistentHeader(
                pinned: false,
                delegate: _buildHeader(count: 0, isLoading: true),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spaceLG,
                  AppTheme.spaceMD,
                  AppTheme.spaceLG,
                  AppTheme.spaceLG,
                ),
                sliver: SliverList.builder(
                  itemCount: 5,
                  itemBuilder: (_, __) => const Padding(
                    padding: EdgeInsets.only(bottom: AppTheme.spaceMD),
                    child: HelperCardSkeleton(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Compact pickup + duration + travelers strip rendered as the hero's footer.
class _TripSummaryPills extends StatelessWidget {
  final String pickupName;
  final String destinationName;
  final int durationInMinutes;
  final int travelers;
  final bool requiresCar;

  const _TripSummaryPills({
    required this.pickupName,
    required this.destinationName,
    required this.durationInMinutes,
    required this.travelers,
    required this.requiresCar,
  });

  static String _formatDuration(int m) {
    if (m % 60 == 0) return '${m ~/ 60}h';
    return '${m ~/ 60}h ${m % 60}m';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceSM),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _Pill(icon: Icons.trip_origin_rounded, label: pickupName, wide: true),
          _Pill(icon: Icons.flag_rounded, label: destinationName, wide: true),
          _Pill(
            icon: Icons.schedule_rounded,
            label: _formatDuration(durationInMinutes),
          ),
          _Pill(icon: Icons.group_rounded, label: '$travelers'),
          if (requiresCar)
            const _Pill(icon: Icons.directions_car_rounded, label: 'Car'),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool wide;
  const _Pill({required this.icon, required this.label, this.wide = false});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: wide ? 150 : 96),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Icon(icon, color: Colors.white, size: 13),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchCountBadge extends StatelessWidget {
  final int count;
  final bool isLoading;

  const _MatchCountBadge({required this.count, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: Colors.white.withValues(alpha: 0.26)),
      ),
      child: Text(
        isLoading ? 'Live' : '$count found',
        style: BrandTypography.overline(color: Colors.white),
      ),
    );
  }
}

class _HelpersRevealPanel extends StatefulWidget {
  final List<HelperSearchResult> helpers;
  final ValueChanged<HelperSearchResult> onTap;

  const _HelpersRevealPanel({required this.helpers, required this.onTap});

  @override
  State<_HelpersRevealPanel> createState() => _HelpersRevealPanelState();
}

class _HelpersRevealPanelState extends State<_HelpersRevealPanel> {
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 950), () {
      if (mounted) setState(() => _revealed = true);
    });
  }

  @override
  void didUpdateWidget(covariant _HelpersRevealPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.helpers != widget.helpers) {
      _revealed = false;
      Future<void>.delayed(const Duration(milliseconds: 950), () {
        if (mounted) setState(() => _revealed = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: _revealed
          ? Column(
              key: const ValueKey('helpers'),
              children: [
                for (var i = 0; i < widget.helpers.length; i++)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(
                      milliseconds: 360 + (i * 70).clamp(0, 420),
                    ),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 18 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.spaceMD),
                      child: HelperSuitabilityCard(
                        helper: widget.helpers[i],
                        onTap: () => widget.onTap(widget.helpers[i]),
                      ),
                    ),
                  ),
              ],
            )
          : _RankingWarmup(count: widget.helpers.length),
    );
  }
}

class _RankingWarmup extends StatelessWidget {
  final int count;

  const _RankingWarmup({required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('ranking'),
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spaceLG),
          decoration: BoxDecoration(
            gradient: BrandTokens.primaryGradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: BrandTokens.ctaBlueGlow,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: BrandTokens.accentAmber,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: BrandTokens.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          count > 0
                              ? 'Ranking $count helpers'
                              : 'Searching helpers',
                          style: BrandTypography.title(
                            color: Colors.white,
                            weight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Matching trust, arrival time, language and price.',
                          style: BrandTypography.caption(
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceLG),
              const LinearProgressIndicator(
                color: BrandTokens.accentAmber,
                backgroundColor: Color(0x33FFFFFF),
                minHeight: 6,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spaceMD),
        for (var i = 0; i < 3; i++)
          const Padding(
            padding: EdgeInsets.only(bottom: AppTheme.spaceMD),
            child: HelperCardSkeleton(),
          ),
      ],
    );
  }
}
