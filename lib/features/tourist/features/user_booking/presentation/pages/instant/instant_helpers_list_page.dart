import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../../core/router/app_router.dart';
import '../../../../../../../core/theme/app_theme.dart';
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

  HeroSliverHeader _buildHeader({
    required int count,
    required bool isLoading,
  }) {
    return HeroSliverHeader(
      title: isLoading ? 'Searching nearby helpers...' : 'Available helpers',
      subtitle: isLoading
          ? "We're ranking matches by rating, distance and price"
          : '$count match${count == 1 ? '' : 'es'} for your trip',
      leadingIcon: Icons.travel_explore_rounded,
      height: 220,
      footer: _TripSummaryPills(
        pickupName: pickup.name,
        durationInMinutes: durationInMinutes,
        travelers: travelers,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spaceLG,
                      AppTheme.spaceMD,
                      AppTheme.spaceLG,
                      AppTheme.spaceLG,
                    ),
                    sliver: SliverList.separated(
                      itemCount: state.helpers.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppTheme.spaceMD),
                      itemBuilder: (_, i) {
                        final h = state.helpers[i];
                        return HelperSuitabilityCard(
                          helper: h,
                          onTap: () => _onTap(context, h),
                        );
                      },
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
  final int durationInMinutes;
  final int travelers;

  const _TripSummaryPills({
    required this.pickupName,
    required this.durationInMinutes,
    required this.travelers,
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
      ),
      child: Row(
        children: [
          const Icon(
            Icons.trip_origin_rounded,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              pickupName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          _Pill(
            icon: Icons.schedule_rounded,
            label: _formatDuration(durationInMinutes),
          ),
          const SizedBox(width: 6),
          _Pill(
            icon: Icons.group_rounded,
            label: '$travelers',
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
