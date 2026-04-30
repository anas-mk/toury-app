import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../core/theme/brand_typography.dart';
import '../../../../../../core/widgets/animations/fade_in_slide.dart';
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
    _upcomingCubit.close();
    _historyCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _requestsCubit),
        BlocProvider.value(value: _upcomingCubit),
        BlocProvider.value(value: _historyCubit),
      ],
      child: Scaffold(
        backgroundColor: BrandTokens.bgSoft,
        appBar: AppBar(
          elevation: 0,
          centerTitle: false,
          backgroundColor: BrandTokens.surfaceWhite,
          foregroundColor: BrandTokens.textPrimary,
          title: Text('Booking Center', style: BrandTokens.heading(fontSize: 20)),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: false,
            indicatorColor: BrandTokens.primaryBlue,
            indicatorWeight: 3,
            labelColor: BrandTokens.primaryBlue,
            unselectedLabelColor: BrandTokens.textSecondary,
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
            _RequestsTab(cubit: _requestsCubit),
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
  const _RequestsTab({required this.cubit});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IncomingRequestsCubit, IncomingRequestsState>(
      builder: (context, state) {
        if (state is IncomingRequestsLoading || state is IncomingRequestsInitial) {
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: 3,
            itemBuilder: (_, __) => const SkeletonBookingCard(),
          );
        }
        if (state is IncomingRequestsLoaded) {
          if (state.requests.isEmpty) {
            return const EmptyStateView(
              icon: Icons.notifications_none_rounded,
              title: 'No new requests',
              subtitle: 'When travelers request your service, they will appear here.',
            );
          }
          return RefreshIndicator.adaptive(
            onRefresh: () async => cubit.refresh(),
            color: BrandTokens.primaryBlue,
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: state.requests.length,
              itemBuilder: (context, index) => FadeInSlide(
                delay: Duration(milliseconds: index * 50),
                child: BookingCard(booking: state.requests[index]),
              ),
            ),
          );
        }
        if (state is IncomingRequestsEmpty) {
          return const EmptyStateView(
            icon: Icons.notifications_none_rounded,
            title: 'No new requests',
            subtitle: 'When travelers request your service, they will appear here.',
          );
        }
        if (state is IncomingRequestsError) {
          return Center(child: Text(state.message));
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
        if (state is UpcomingBookingsLoading) {
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: 3,
            itemBuilder: (_, __) => const SkeletonBookingCard(),
          );
        }
        if (state is UpcomingBookingsLoaded) {
          if (state.bookings.isEmpty) {
            return const EmptyStateView(
              icon: Icons.calendar_today_rounded,
              title: 'No upcoming trips',
              subtitle: 'Confirmed bookings will show up here for you to start.',
            );
          }
          return RefreshIndicator.adaptive(
            onRefresh: () async => cubit.load(),
            color: BrandTokens.primaryBlue,
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: state.bookings.length,
              itemBuilder: (context, index) => FadeInSlide(
                delay: Duration(milliseconds: index * 50),
                child: BookingCard(booking: state.bookings[index]),
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

  const _HistoryTab({
    required this.cubit,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HelperHistoryCubit, HelperHistoryState>(
      builder: (context, state) {
        if (state is HelperHistoryLoading) {
          return ListView.builder(
            padding: const EdgeInsets.all(20),
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
            color: BrandTokens.primaryBlue,
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: state.bookings.length + (state.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= state.bookings.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator.adaptive()),
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
        return const SizedBox.shrink();
      },
    );
  }
}
