import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/widgets/app_network_image.dart';
import '../../../../../../core/widgets/basic_app_bar.dart';
import '../../../../../../core/widgets/custom_card.dart';
import '../../domain/entities/booking_detail_entity.dart';
import '../cubits/my_bookings_cubit.dart';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  final List<String> _tabs = ['All', 'Upcoming', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final status = _tabs[_tabController.index];
    context.read<MyBookingsCubit>().getBookings(status: status, refresh: true);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final status = _tabs[_tabController.index];
      context.read<MyBookingsCubit>().getBookings(status: status);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<MyBookingsCubit>()..getBookings(status: 'All', refresh: true),
      child: Scaffold(
        appBar: BasicAppBar(
          title: 'My Bookings',
          showBackButton: true,
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
          ),
        ),
        body: BlocBuilder<MyBookingsCubit, MyBookingsState>(
          builder: (context, state) {
            if (state is MyBookingsLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is MyBookingsError) {
              return Center(child: Text('Error: ${state.message}'));
            }

            if (state is MyBookingsLoaded) {
              if (state.bookings.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                onRefresh: () async {
                  final status = _tabs[_tabController.index];
                  context.read<MyBookingsCubit>().getBookings(status: status, refresh: true);
                },
                child: ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: state.bookings.length + (state.hasNextPage ? 1 : 0),
                  separatorBuilder: (context, index) => const SizedBox(height: 15),
                  itemBuilder: (context, index) {
                    if (index == state.bookings.length) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final booking = state.bookings[index];
                    return _buildBookingCard(context, booking);
                  },
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          const Text('No bookings found', style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text('You haven\'t made any bookings yet.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, BookingDetailEntity booking) {
    return CustomCard(
      onTap: () => context.push('/booking-details/${booking.id}', extra: {'booking': booking}),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTypeBadge(booking.type),
              _buildStatusText(booking.status),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AppNetworkImage(
                  imageUrl: booking.helper?.profileImageUrl ?? '',
                  width: 50,
                  height: 50,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.helper?.name ?? 'Waiting for Helper',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${DateFormat('MMM dd, yyyy').format(booking.requestedDate)} • ${booking.destinationCity}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${booking.totalPrice} ${booking.currency}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(BookingType type) {
    final isInstant = type == BookingType.instant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isInstant ? Colors.amber.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isInstant ? Icons.bolt : Icons.calendar_today, size: 12, color: isInstant ? Colors.amber[800] : Colors.blue),
          const SizedBox(width: 4),
          Text(
            isInstant ? 'Instant' : 'Scheduled',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isInstant ? Colors.amber[800] : Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusText(BookingStatus status) {
    Color color;
    switch (status) {
      case BookingStatus.pending: color = Colors.orange; break;
      case BookingStatus.confirmed: color = Colors.green; break;
      case BookingStatus.inProgress: color = Colors.blue; break;
      case BookingStatus.completed: color = Colors.grey; break;
      case BookingStatus.cancelled:
      case BookingStatus.declined: color = Colors.red; break;
      default: color = Colors.black;
    }
    return Text(
      status.name.toUpperCase(),
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
    );
  }
}
