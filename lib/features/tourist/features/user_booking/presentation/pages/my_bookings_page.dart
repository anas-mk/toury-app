import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/widgets/app_network_image.dart';
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

  final MyBookingsCubit _cubit = sl<MyBookingsCubit>()..getBookings(status: 'All', refresh: true);

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
    _cubit.getBookings(status: status, refresh: true);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final status = _tabs[_tabController.index];
      _cubit.getBookings(status: status);
    }
  }

  @override
  void dispose() {
    _cubit.close();
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Activity'),
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: isDark ? Colors.white : Colors.black,
            labelColor: isDark ? Colors.white : Colors.black,
            unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                return _buildEmptyState(isDark);
              }

              return RefreshIndicator(
                onRefresh: () async {
                  final status = _tabs[_tabController.index];
                  _cubit.getBookings(status: status, refresh: true);
                },
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: state.bookings.length + (state.hasNextPage ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == state.bookings.length) {
                      return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
                    }
                    final booking = state.bookings[index];
                    return _buildBookingItem(context, booking, isDark);
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

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_car_outlined, size: 80, color: isDark ? Colors.white24 : Colors.black12),
          const SizedBox(height: 24),
          const Text('No activity yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('You don\'t have any bookings matching this status.', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildBookingItem(BuildContext context, BookingDetailEntity booking, bool isDark) {
    return InkWell(
      onTap: () => context.push('/booking-details/${booking.id}', extra: {'booking': booking}),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF6F6F6),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.hardEdge,
              child: booking.helper?.profileImageUrl != null
                  ? AppNetworkImage(imageUrl: booking.helper!.profileImageUrl!, width: 56, height: 56)
                  : Icon(Icons.person, color: isDark ? Colors.white54 : Colors.black54),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.destinationCity.isNotEmpty ? booking.destinationCity : 'Unknown Destination',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM dd, yyyy • h:mm a').format(booking.requestedDate),
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  _buildStatusText(booking.status),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'EGP ${booking.estimatedPrice}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (booking.paymentStatus != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    booking.paymentStatus!.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: booking.paymentStatus?.toLowerCase() == 'paid' ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
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
      case BookingStatus.cancelledByUser:
      case BookingStatus.cancelledByHelper:
      case BookingStatus.cancelledBySystem:
      case BookingStatus.declined: color = Colors.red; break;
      case BookingStatus.confirmedAwaitingPayment: color = Colors.orange; break;
      default: color = Colors.black;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
