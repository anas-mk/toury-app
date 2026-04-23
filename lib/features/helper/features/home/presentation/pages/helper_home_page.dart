import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:toury/features/helper/features/helper_bookings/presentation/cubit/helper_bookings_cubit.dart';
import 'package:toury/features/helper/features/helper_bookings/presentation/cubit/helper_bookings_state.dart';
import '../../../../../../core/router/app_router.dart';
import '../widgets/active_trip_card.dart';
import '../widgets/helper_status_header.dart';
import '../widgets/history_shortcut_card.dart';
import '../widgets/requests_preview_section.dart';
import '../widgets/upcoming_trips_section.dart';

class HelperHomePage extends StatefulWidget {
  const HelperHomePage({super.key});

  @override
  State<HelperHomePage> createState() => _HelperHomePageState();
}

class _HelperHomePageState extends State<HelperHomePage> {
  @override
  void initState() {
    super.initState();
    context.read<HelperBookingsCubit>().loadAllBookings();
  }

  Future<void> _onRefresh() async {
    await context.read<HelperBookingsCubit>().loadAllBookings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: BlocConsumer<HelperBookingsCubit, HelperBookingsState>(
          listener: (context, state) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.red),
              );
            }
          },
          builder: (context, state) {
            if (state.isLoading && state.requests.isEmpty && state.upcoming.isEmpty && state.active == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                  sliver: SliverToBoxAdapter(
                    child: HelperStatusHeader(
                      name: 'Professional Helper', // Should come from profile cubit ideally
                      isBusy: state.active != null,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      ActiveTripCard(
                        activeTrip: state.active,
                        isActionLoading: state.actionLoadingId == state.active?.id,
                        onEndTrip: () => context.read<HelperBookingsCubit>().endTrip(state.active!.id),
                      ),
                      const SizedBox(height: 24),
                      RequestsPreviewSection(
                        requests: state.requests,
                        actionLoadingId: state.actionLoadingId,
                        onAccept: (id) => context.read<HelperBookingsCubit>().acceptBooking(id),
                        onViewAll: () => context.push(AppRouter.helperRequests),
                      ),
                      const SizedBox(height: 24),
                      UpcomingTripsSection(
                        upcoming: state.upcoming,
                        actionLoadingId: state.actionLoadingId,
                        onStart: (id) => context.read<HelperBookingsCubit>().startTrip(id),
                        onViewAll: () => context.push(AppRouter.helperUpcoming),
                      ),
                      const SizedBox(height: 24),
                      HistoryShortcutCard(
                        onTap: () => context.push(AppRouter.helperHistory),
                      ),
                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
