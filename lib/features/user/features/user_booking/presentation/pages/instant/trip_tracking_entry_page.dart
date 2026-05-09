import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/di/injection_container.dart';
import '../../cubits/instant_booking_cubit.dart';
import '../../cubits/instant_booking_state.dart';
import 'trip_tracking_page.dart';

/// Cold-start / push deep-link entry for live trip tracking without an
/// existing [InstantBookingCubit] in the widget tree.
class TripTrackingEntryPage extends StatefulWidget {
  const TripTrackingEntryPage({super.key, required this.bookingId});

  final String bookingId;

  @override
  State<TripTrackingEntryPage> createState() => _TripTrackingEntryPageState();
}

class _TripTrackingEntryPageState extends State<TripTrackingEntryPage> {
  late final InstantBookingCubit _cubit = sl<InstantBookingCubit>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _cubit.hydrateForTripDeepLink(widget.bookingId);
    });
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<InstantBookingCubit, InstantBookingState>(
        builder: (context, state) {
          if (state is InstantBookingAccepted) {
            return TripTrackingPage(
              cubit: _cubit,
              bookingId: widget.bookingId,
              helper: null,
            );
          }
          if (state is InstantBookingError) {
            return Scaffold(
              appBar: AppBar(title: const Text('Trip')),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(state.message, textAlign: TextAlign.center),
                ),
              ),
            );
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}
