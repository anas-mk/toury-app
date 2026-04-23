import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/di/injection_container.dart';
import '../cubit/my_bookings_cubit.dart';
import '../widgets/booking_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_view.dart';
import 'booking_details_page.dart';

class MyBookingsPage extends StatelessWidget {
  const MyBookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Bookings'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Completed'),
              Tab(text: 'Cancelled'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _BookingsListTab(status: 'upcoming'),
            _BookingsListTab(status: 'completed'),
            _BookingsListTab(status: 'cancelled'),
          ],
        ),
      ),
    );
  }
}

class _BookingsListTab extends StatefulWidget {
  final String status;
  const _BookingsListTab({required this.status});

  @override
  State<_BookingsListTab> createState() => _BookingsListTabState();
}

class _BookingsListTabState extends State<_BookingsListTab> {
  late final MyBookingsCubit _cubit;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _cubit = sl<MyBookingsCubit>()..loadBookings(status: widget.status, isRefresh: true);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final state = _cubit.state;
      if (state is MyBookingsSuccess && state.hasMore) {
        _cubit.loadBookings(status: widget.status);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<MyBookingsCubit, MyBookingsState>(
        builder: (context, state) {
          if (state is MyBookingsInitial || (state is MyBookingsLoading && !state.isPagination)) {
            return const LoadingIndicator();
          } else if (state is MyBookingsError) {
            return ErrorView(
              message: state.message,
              onRetry: () => _cubit.loadBookings(status: widget.status, isRefresh: true),
            );
          } else if (state is MyBookingsSuccess || (state is MyBookingsLoading && state.isPagination)) {
            final bookings = state is MyBookingsSuccess 
                ? state.bookings 
                : (context.read<MyBookingsCubit>().state as MyBookingsSuccess).bookings; // Simplified for brevity

            if (bookings.isEmpty) {
              return const EmptyState(message: 'No bookings found in this category.');
            }

            return RefreshIndicator(
              onRefresh: () => _cubit.loadBookings(status: widget.status, isRefresh: true),
              child: ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: bookings.length + (state is MyBookingsLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= bookings.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final booking = bookings[index];
                  return BookingCard(
                    booking: booking,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => BookingDetailsPage(bookingId: booking.id)),
                      );
                    },
                  );
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
