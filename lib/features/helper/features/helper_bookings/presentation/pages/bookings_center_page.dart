import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_dimens.dart';
import '../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../core/theme/brand_typography.dart';
import '../../../../../../core/widgets/animations/fade_in_slide.dart';
import '../../../../../../core/widgets/app_error_state.dart';
import '../../../../../../core/widgets/app_loading.dart';
import '../../../../../../core/di/injection_container.dart';
import '../cubit/helper_bookings_cubits.dart';
import '../widgets/shared/empty_state_view.dart';
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
    _loadCurrentTab();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _loadCurrentTab();
  }

  void _loadCurrentTab() {
    switch (_tabController.index) {
      case 0:
        if (_requestsCubit.state is IncomingRequestsInitial) {
          _requestsCubit.load();
        }
        break;
      case 1:
        if (_upcomingCubit.state is UpcomingBookingsInitial) {
          _upcomingCubit.load();
        }
        break;
      case 2:
        if (_historyCubit.state is HelperHistoryInitial) {
          _historyCubit.load();
        }
        break;
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
        appBar: AppBar(
          elevation: 0,
          centerTitle: false,
          surfaceTintColor: Colors.transparent,
          backgroundColor: palette.surface,
          foregroundColor: palette.textPrimary,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Booking Center', style: BrandTokens.heading(fontSize: 20)),
              Text(
                'Requests, live trips, and completed history',
                style: BrandTypography.caption(color: palette.textSecondary),
              ),
            ],
          ),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: false,
            indicatorColor: palette.primary,
            indicatorWeight: 3,
            labelColor: palette.primary,
            unselectedLabelColor: palette.textSecondary,
            dividerColor: Colors.transparent,
            labelStyle: BrandTypography.caption(weight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Requests'),
              Tab(text: 'Upcoming'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
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
    );
  }
}

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
              _FlowStatusStrip(
                text:
                    'Requests here should be reviewed quickly to keep your acceptance rate healthy.',
              ),
              _RequestTypeFilterBar(
                selected: state.filter,
                onChanged: cubit.changeFilter,
              ),
              Expanded(
                child: state.requests.isEmpty
                    ? const EmptyStateView(
                        icon: Icons.notifications_none_rounded,
                        title: 'No new requests',
                        subtitle:
                            'When travelers request your service, they will appear here.',
                      )
                    : RefreshIndicator.adaptive(
                        onRefresh: () async => cubit.refresh(),
                        color: Theme.of(context).colorScheme.primary,
                        child: ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.all(AppSpacing.pageGutter),
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
              const _FlowStatusStrip(
                text: 'Loading more requests based on your selected filter.',
              ),
              _RequestTypeFilterBar(
                selected: state.filter,
                onChanged: cubit.changeFilter,
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.pageGutter),
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
              const _FlowStatusStrip(
                text:
                    'No pending traveler requests right now. Keep location and availability on.',
              ),
              _RequestTypeFilterBar(
                selected: state.filter,
                onChanged: cubit.changeFilter,
              ),
              const Expanded(
                child: EmptyStateView(
                  icon: Icons.notifications_none_rounded,
                  title: 'No new requests',
                  subtitle:
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
            return const EmptyStateView(
              icon: Icons.calendar_today_rounded,
              title: 'No upcoming trips',
              subtitle:
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
            return const EmptyStateView(
              icon: Icons.history_rounded,
              title: 'No history yet',
              subtitle: 'Your completed trips will be archived here.',
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

class _RequestTypeFilterBar extends StatelessWidget {
  final RequestFilterType selected;
  final ValueChanged<RequestFilterType> onChanged;

  const _RequestTypeFilterBar({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm + AppSpacing.xxs,
      ),
      color: palette.surface,
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: RequestFilterType.values.map((filter) {
          final selectedFilter = filter == selected;
          return ChoiceChip(
            label: Text(filter.displayName),
            selected: selectedFilter,
            onSelected: (_) => onChanged(filter),
            selectedColor: palette.primary.withValues(alpha: 0.15),
            labelStyle: BrandTypography.caption(
              weight: FontWeight.w600,
              color: selectedFilter ? palette.primary : palette.textSecondary,
            ),
            side: BorderSide(
              color: selectedFilter
                  ? palette.primary.withValues(alpha: 0.35)
                  : palette.border,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FlowStatusStrip extends StatelessWidget {
  final String text;
  const _FlowStatusStrip({required this.text});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: palette.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: palette.primary.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: AppSize.iconSm,
            color: palette.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: BrandTypography.caption(color: palette.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
