import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../core/theme/brand_typography.dart';
import '../../../../../../core/widgets/basic_app_bar.dart';
import '../cubit/incoming_requests_cubit.dart';
import '../widgets/shared/request_card.dart';
import '../widgets/shared/skeleton_booking_card.dart';
import '../widgets/shared/empty_state_view.dart';

class IncomingRequestsPage extends StatefulWidget {
  const IncomingRequestsPage({super.key});

  @override
  State<IncomingRequestsPage> createState() => _IncomingRequestsPageState();
}

class _IncomingRequestsPageState extends State<IncomingRequestsPage> with SingleTickerProviderStateMixin {
  late final IncomingRequestsCubit _cubit;
  late final ScrollController _scrollController;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _cubit = sl<IncomingRequestsCubit>()..load();
    _scrollController = ScrollController()..addListener(_onScroll);
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _cubit.loadMore();
    }
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final filter = _indexToFilter(_tabController.index);
      _cubit.changeFilter(filter);
    }
  }

  RequestFilterType _indexToFilter(int index) {
    switch (index) {
      case 0: return RequestFilterType.all;
      case 1: return RequestFilterType.scheduled;
      case 2: return RequestFilterType.instant;
      default: return RequestFilterType.all;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: BrandTokens.bgSoft,
        appBar: const BasicAppBar(
          title: 'Booking Requests',
          showBackButton: true,
        ),
        body: Column(
          children: [
            _buildFilterTabs(),
            Expanded(
              child: BlocBuilder<IncomingRequestsCubit, IncomingRequestsState>(
                builder: (context, state) {
                  if (state is IncomingRequestsInitial || state is IncomingRequestsLoading) {
                    return _buildLoadingList();
                  }

                  if (state is IncomingRequestsEmpty) {
                    return _buildEmptyState(state.filter);
                  }

                  if (state is IncomingRequestsError) {
                    return _buildErrorState(state.message);
                  }

                  if (state is IncomingRequestsLoaded || state is IncomingRequestsLoadingMore) {
                    final requests = state is IncomingRequestsLoaded 
                        ? state.requests 
                        : (state as IncomingRequestsLoadingMore).currentRequests;
                    
                    final hasNextPage = state is IncomingRequestsLoaded 
                        ? state.hasNextPage 
                        : true;

                    return RefreshIndicator.adaptive(
                      onRefresh: () => _cubit.refresh(),
                      color: BrandTokens.primaryBlue,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(20),
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        itemCount: requests.length + (hasNextPage ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index < requests.length) {
                            return RequestCard(request: requests[index]);
                          }
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(child: CircularProgressIndicator.adaptive()),
                          );
                        },
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: BrandTokens.surfaceWhite,
        border: Border(
          bottom: BorderSide(color: BrandTokens.borderSoft, width: 1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: BrandTokens.primaryBlue,
        unselectedLabelColor: BrandTokens.textMuted,
        indicatorColor: BrandTokens.primaryBlue,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: BrandTokens.heading(fontSize: 14, fontWeight: FontWeight.w700, color: BrandTokens.primaryBlue),
        unselectedLabelStyle: BrandTokens.heading(fontSize: 14, fontWeight: FontWeight.w500, color: BrandTokens.textMuted),
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Scheduled'),
          Tab(text: 'Instant'),
        ],
      ),
    );
  }

  Widget _buildLoadingList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 6,
      itemBuilder: (context, index) => const SkeletonBookingCard(),
    );
  }

  Widget _buildEmptyState(RequestFilterType filter) {
    String title = 'No Requests Yet';
    String subtitle = 'New booking requests will appear here when travelers search for guides in your area.';
    
    if (filter == RequestFilterType.instant) {
      title = 'No Instant Requests';
      subtitle = 'Go online to start receiving instant booking requests from nearby travelers.';
    } else if (filter == RequestFilterType.scheduled) {
      title = 'No Scheduled Requests';
      subtitle = 'You don\'t have any scheduled booking requests at the moment.';
    }

    return RefreshIndicator.adaptive(
      onRefresh: () => _cubit.refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          alignment: Alignment.center,
          child: EmptyStateView(
            icon: Icons.assignment_outlined,
            title: title,
            subtitle: subtitle,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: BrandTokens.dangerRed, size: 48),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: BrandTypography.title(),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: BrandTypography.body(color: BrandTokens.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _cubit.load(),
              style: ElevatedButton.styleFrom(
                backgroundColor: BrandTokens.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
