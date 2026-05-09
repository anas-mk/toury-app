import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_dimens.dart';
import '../../../../../../core/widgets/animations/fade_in_slide.dart';
import '../../../../../../core/widgets/app_empty_state.dart';
import '../../../../../../core/widgets/app_error_state.dart';
import '../../../../../../core/widgets/app_loading.dart';
import '../../../../../../core/di/injection_container.dart';
import '../cubit/helper_bookings_cubits.dart';
import '../widgets/shared/skeleton_booking_card.dart';

import '../widgets/shared/booking_card.dart';

class BookingsCenterPage extends StatefulWidget {
  final int initialTabIndex;
  const BookingsCenterPage({super.key, this.initialTabIndex = 0});

  @override
  State<BookingsCenterPage> createState() => _BookingsCenterPageState();
}

class _BookingsCenterPageState extends State<BookingsCenterPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final IncomingRequestsCubit _requestsCubit;
  late final UpcomingBookingsCubit _upcomingCubit;
  late final HelperHistoryCubit _historyCubit;
  final ScrollController _historyScrollController = ScrollController();
  final ScrollController _requestsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
    _requestsCubit = sl<IncomingRequestsCubit>();
    _upcomingCubit = sl<UpcomingBookingsCubit>();
    _historyCubit = sl<HelperHistoryCubit>();
    _historyScrollController.addListener(() {
      if (_historyScrollController.position.pixels >=
          _historyScrollController.position.maxScrollExtent - 180) {
        _historyCubit.loadMore();
      }
    });
    _requestsScrollController.addListener(() {
      if (_requestsScrollController.position.pixels >=
          _requestsScrollController.position.maxScrollExtent - 180) {
        _requestsCubit.loadMore();
      }
    });
    _tabController.addListener(_onTabChanged);
    _ensureSummariesLoaded();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {}); // Refresh hero card selection + counts
    _ensureSummariesLoaded();
  }

  /// Loads all three sections so hero stat cards show counts without visiting each tab.
  void _ensureSummariesLoaded() {
    if (_requestsCubit.state is IncomingRequestsInitial) {
      _requestsCubit.load();
    }
    if (_upcomingCubit.state is UpcomingBookingsInitial) {
      _upcomingCubit.load();
    }
    if (_historyCubit.state is HelperHistoryInitial) {
      _historyCubit.load();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _historyScrollController.dispose();
    _requestsScrollController.dispose();
    // Shared singleton used across helper pages; do not close from UI layer.
    _upcomingCubit.close();
    _historyCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _requestsCubit),
        BlocProvider.value(value: _upcomingCubit),
        BlocProvider.value(value: _historyCubit),
      ],
      child: Scaffold(
        backgroundColor: palette.scaffold,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              FadeInSlide(
                duration: const Duration(milliseconds: 500),
                child: _HeroHeader(controller: _tabController),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _RequestsTab(
                      cubit: _requestsCubit,
                      scrollController: _requestsScrollController,
                    ),
                    _UpcomingTab(cubit: _upcomingCubit),
                    _HistoryTab(
                      cubit: _historyCubit,
                      scrollController: _historyScrollController,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  HERO HEADER WITH LIVE STATS
// ──────────────────────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final TabController controller;
  const _HeroHeader({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bookings',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const _LivePulse(),
                        const SizedBox(width: 6),
                        Text(
                          'Live · synced just now',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: palette.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _CircleIconButton(
                icon: Icons.filter_list_rounded,
                onTap: () {},
              ),
              const SizedBox(width: 8),
              _CircleIconButton(
                icon: Icons.calendar_today_outlined,
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          _StatsRow(controller: controller),
        ],
      ),
    );
  }
}

class _LivePulse extends StatefulWidget {
  const _LivePulse();

  @override
  State<_LivePulse> createState() => _LivePulseState();
}

class _LivePulseState extends State<_LivePulse>
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
    return SizedBox(
      width: 10,
      height: 10,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              final t = _ctrl.value;
              return Container(
                width: 10 + 8 * t,
                height: 10 + 8 * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF22C55E).withValues(alpha: 0.4 * (1 - t)),
                ),
              );
            },
          ),
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF22C55E),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final TabController controller;
  const _StatsRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: BlocBuilder<IncomingRequestsCubit, IncomingRequestsState>(
            builder: (context, state) {
              final count = _requestsCount(state);
              return _StatCard(
                onTap: () => controller.animateTo(0),
                isActive: controller.index == 0,
                icon: Icons.flash_on_rounded,
                label: 'Requests',
                value: count != null ? '$count' : '—',
                color: const Color(0xFFFF8C42),
                showDot: count != null && count > 0,
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: BlocBuilder<UpcomingBookingsCubit, UpcomingBookingsState>(
            builder: (context, state) {
              final count = state is UpcomingBookingsLoaded
                  ? state.bookings.length
                  : null;
              return _StatCard(
                onTap: () => controller.animateTo(1),
                isActive: controller.index == 1,
                icon: Icons.event_available_rounded,
                label: 'Upcoming',
                value: count != null ? '$count' : '—',
                color: const Color(0xFF7B61FF),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: BlocBuilder<HelperHistoryCubit, HelperHistoryState>(
            builder: (context, state) {
              final count = state is HelperHistoryLoaded ? state.bookings.length : null;
              return _StatCard(
                onTap: () => controller.animateTo(2),
                isActive: controller.index == 2,
                icon: Icons.history_rounded,
                label: 'History',
                value: count != null ? '$count' : '—',
                color: const Color(0xFF00B8A9),
              );
            },
          ),
        ),
      ],
    );
  }

  int? _requestsCount(IncomingRequestsState state) {
    if (state is IncomingRequestsLoaded) return state.totalCount;
    if (state is IncomingRequestsLoadingMore) return state.currentRequests.length;
    if (state is IncomingRequestsEmpty) return 0;
    return null;
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isActive;
  final bool showDot;
  final VoidCallback onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isActive,
    required this.onTap,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        gradient: isActive
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: palette.isDark ? 0.30 : 0.18),
                  color.withValues(alpha: palette.isDark ? 0.14 : 0.06),
                ],
              )
            : null,
        color: isActive ? null : palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? color.withValues(alpha: 0.45)
              : palette.border,
          width: isActive ? 1.2 : 0.5,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withValues(alpha: palette.isDark ? 0.20 : 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: palette.isDark ? 0.22 : 0.16),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(icon, color: color, size: 16),
                    ),
                    const Spacer(),
                    if (showDot)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.5),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                    fontSize: 20,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: palette.textMuted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
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

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: palette.surface,
            shape: BoxShape.circle,
            border: Border.all(color: palette.border),
          ),
          child: Icon(icon, color: palette.textSecondary, size: 19),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  REQUESTS TAB
// ──────────────────────────────────────────────────────────────────────────────

class _RequestsTab extends StatelessWidget {
  final IncomingRequestsCubit cubit;
  final ScrollController? scrollController;
  const _RequestsTab({required this.cubit, this.scrollController});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IncomingRequestsCubit, IncomingRequestsState>(
      builder: (context, state) {
        if (state is IncomingRequestsLoading ||
            state is IncomingRequestsInitial) {
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.pageGutter),
            itemCount: 3,
            itemBuilder: (_, __) => const SkeletonBookingCard(),
          );
        }
        if (state is IncomingRequestsLoaded) {
          return Column(
            children: [
              _RequestTypeFilterBar(
                selected: state.filter,
                onChanged: cubit.changeFilter,
              ),
              Expanded(
                child: state.requests.isEmpty
                    ? const AppEmptyState(
                        icon: Icons.notifications_none_rounded,
                        title: 'No new requests',
                        message:
                            'When travelers request your service, they will appear here.',
                      )
                    : RefreshIndicator.adaptive(
                        onRefresh: () async => cubit.refresh(),
                        color: Theme.of(context).colorScheme.primary,
                        child: ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.pageGutter,
                            4,
                            AppSpacing.pageGutter,
                            AppSpacing.pageGutter,
                          ),
                          itemCount:
                              state.requests.length +
                              (state.hasNextPage ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= state.requests.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(child: AppSpinner.large()),
                              );
                            }
                            return FadeInSlide(
                              delay: Duration(milliseconds: index * 50),
                              child: BookingCard(
                                booking: state.requests[index],
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        }
        if (state is IncomingRequestsLoadingMore) {
          return Column(
            children: [
              _RequestTypeFilterBar(
                selected: state.filter,
                onChanged: cubit.changeFilter,
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageGutter,
                    4,
                    AppSpacing.pageGutter,
                    AppSpacing.pageGutter,
                  ),
                  itemCount: state.currentRequests.length + 1,
                  itemBuilder: (context, index) {
                    if (index >= state.currentRequests.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: AppSpinner.large()),
                      );
                    }
                    return FadeInSlide(
                      delay: Duration(milliseconds: index * 50),
                      child: BookingCard(booking: state.currentRequests[index]),
                    );
                  },
                ),
              ),
            ],
          );
        }
        if (state is IncomingRequestsEmpty) {
          return Column(
            children: [
              _RequestTypeFilterBar(
                selected: state.filter,
                onChanged: cubit.changeFilter,
              ),
              const Expanded(
                child: AppEmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: 'No new requests',
                  message:
                      'When travelers request your service, they will appear here.',
                ),
              ),
            ],
          );
        }
        if (state is IncomingRequestsError) {
          return Center(
            child: AppErrorState(
              message: state.message,
              onRetry: () => cubit.refresh(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl,
                vertical: AppSpacing.xl,
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  UPCOMING TAB
// ──────────────────────────────────────────────────────────────────────────────

class _UpcomingTab extends StatelessWidget {
  final UpcomingBookingsCubit cubit;
  const _UpcomingTab({required this.cubit});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UpcomingBookingsCubit, UpcomingBookingsState>(
      builder: (context, state) {
        if (state is UpcomingBookingsInitial ||
            state is UpcomingBookingsLoading) {
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.pageGutter),
            itemCount: 3,
            itemBuilder: (_, __) => const SkeletonBookingCard(),
          );
        }
        if (state is UpcomingBookingsLoaded) {
          if (state.bookings.isEmpty) {
            return const AppEmptyState(
              icon: Icons.calendar_today_rounded,
              title: 'No upcoming trips',
              message:
                  'Confirmed bookings will show up here for you to start.',
            );
          }
          return RefreshIndicator.adaptive(
            onRefresh: () async => cubit.load(),
            color: Theme.of(context).colorScheme.primary,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.pageGutter),
              itemCount: state.bookings.length,
              itemBuilder: (context, index) => FadeInSlide(
                delay: Duration(milliseconds: index * 50),
                child: BookingCard(booking: state.bookings[index]),
              ),
            ),
          );
        }
        if (state is UpcomingBookingsError) {
          return Center(
            child: AppErrorState(
              message: state.message,
              onRetry: () => cubit.load(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl,
                vertical: AppSpacing.xl,
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  HISTORY TAB
// ──────────────────────────────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  final HelperHistoryCubit cubit;
  final ScrollController scrollController;

  const _HistoryTab({required this.cubit, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HelperHistoryCubit, HelperHistoryState>(
      builder: (context, state) {
        if (state is HelperHistoryInitial || state is HelperHistoryLoading) {
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.pageGutter),
            itemCount: 5,
            itemBuilder: (_, __) => const SkeletonBookingCard(),
          );
        }
        if (state is HelperHistoryLoaded) {
          if (state.bookings.isEmpty) {
            return const AppEmptyState(
              icon: Icons.history_rounded,
              title: 'No history yet',
              message: 'Your completed trips will be archived here.',
            );
          }
          return RefreshIndicator.adaptive(
            onRefresh: () async => cubit.load(),
            color: Theme.of(context).colorScheme.primary,
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(AppSpacing.pageGutter),
              itemCount: state.bookings.length + (state.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= state.bookings.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: AppSpinner.large()),
                  );
                }
                return FadeInSlide(
                  delay: Duration(milliseconds: index * 50),
                  child: BookingCard(booking: state.bookings[index]),
                );
              },
            ),
          );
        }
        if (state is HelperHistoryError) {
          return Center(
            child: AppErrorState(
              message: state.message,
              onRetry: () => cubit.load(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl,
                vertical: AppSpacing.xl,
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  REQUEST FILTER (MODERN PILL CHIPS)
// ──────────────────────────────────────────────────────────────────────────────

class _RequestTypeFilterBar extends StatelessWidget {
  final RequestFilterType selected;
  final ValueChanged<RequestFilterType> onChanged;

  const _RequestTypeFilterBar({
    required this.selected,
    required this.onChanged,
  });

  IconData _iconFor(RequestFilterType filter) {
    switch (filter) {
      case RequestFilterType.all:
        return Icons.all_inclusive_rounded;
      case RequestFilterType.scheduled:
        return Icons.event_outlined;
      case RequestFilterType.instant:
        return Icons.flash_on_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: RequestFilterType.values.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final filter = RequestFilterType.values[i];
            final isSelected = filter == selected;
            return _FilterChip(
              icon: _iconFor(filter),
              label: filter.displayName,
              isSelected: isSelected,
              onTap: () => onChanged(filter),
            );
          },
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [palette.primary, palette.primaryStrong],
                  )
                : null,
            color: isSelected ? null : palette.surface,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : palette.border,
              width: 0.8,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: palette.primary.withValues(alpha: 0.30),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : palette.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : palette.textSecondary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
