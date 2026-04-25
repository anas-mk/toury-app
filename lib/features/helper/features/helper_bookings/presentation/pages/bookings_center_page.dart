import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/widgets/animations/fade_in_slide.dart';
import '../../../../../../core/services/haptic_service.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../domain/entities/helper_booking_entities.dart';
import '../cubit/helper_bookings_cubits.dart';
import '../widgets/shared/empty_state_view.dart';
import '../widgets/shared/skeleton_booking_card.dart';

class BookingsCenterPage extends StatefulWidget {
  const BookingsCenterPage({super.key});

  @override
  State<BookingsCenterPage> createState() => _BookingsCenterPageState();
}

class _BookingsCenterPageState extends State<BookingsCenterPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final IncomingRequestsCubit _requestsCubit;
  late final UpcomingBookingsCubit _upcomingCubit;
  late final HelperHistoryCubit _historyCubit;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _requestsCubit = sl<IncomingRequestsCubit>();
    _upcomingCubit = sl<UpcomingBookingsCubit>();
    _historyCubit = sl<HelperHistoryCubit>();
    
    _requestsCubit.load();
    _upcomingCubit.load();
    _historyCubit.load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _requestsCubit.close();
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
        backgroundColor: const Color(0xFF0A0E1A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D1120),
          elevation: 0,
          centerTitle: false,
          title: const Text(
            'Order Center',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
          ),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: false,
            indicatorColor: const Color(0xFF6C63FF),
            indicatorWeight: 3,
            labelColor: const Color(0xFF6C63FF),
            unselectedLabelColor: Colors.white38,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
            _HistoryTab(cubit: _historyCubit),
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
        if (state is IncomingRequestsLoading) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
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
          return RefreshIndicator(
            onRefresh: () async => cubit.load(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.requests.length,
              itemBuilder: (context, index) => FadeInSlide(
                delay: Duration(milliseconds: index * 50),
                child: _BookingItemCard(booking: state.requests[index]),
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
        if (state is UpcomingBookingsLoading) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
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
          return RefreshIndicator(
            onRefresh: () async => cubit.load(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.bookings.length,
              itemBuilder: (context, index) => FadeInSlide(
                delay: Duration(milliseconds: index * 50),
                child: _BookingItemCard(booking: state.bookings[index]),
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
  const _HistoryTab({required this.cubit});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HelperHistoryCubit, HelperHistoryState>(
      builder: (context, state) {
        if (state is HelperHistoryLoading) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
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
          return RefreshIndicator(
            onRefresh: () async => cubit.load(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.bookings.length,
              itemBuilder: (context, index) => FadeInSlide(
                delay: Duration(milliseconds: index * 50),
                child: _BookingItemCard(booking: state.bookings[index]),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _BookingItemCard extends StatelessWidget {
  final HelperBooking booking;
  const _BookingItemCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final isHistory = booking.status == 'completed' || booking.status == 'cancelled';
    
    return GestureDetector(
      onTap: () => context.push('/helper-booking-details/${booking.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F3C),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF6C63FF).withOpacity(0.1),
                  child: Text(
                    booking.travelerName.isNotEmpty ? booking.travelerName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.travelerName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        _formatDate(booking.startTime),
                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: booking.status),
              ],
            ),
            const SizedBox(height: 16),
            _LocationRow(icon: Icons.circle_outlined, color: Colors.green, label: booking.pickupLocation),
            const SizedBox(height: 8),
            _LocationRow(icon: Icons.location_on_rounded, color: Colors.redAccent, label: booking.destinationLocation),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${booking.payout.toStringAsFixed(2)}',
                  style: const TextStyle(color: Color(0xFF00C896), fontWeight: FontWeight.bold, fontSize: 18),
                ),
                if (!isHistory)
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'pending': color = Colors.orange; break;
      case 'confirmed':
      case 'accepted': color = Colors.blue; break;
      case 'completed': color = Colors.green; break;
      case 'cancelled': color = Colors.red; break;
      default: color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _LocationRow({required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
