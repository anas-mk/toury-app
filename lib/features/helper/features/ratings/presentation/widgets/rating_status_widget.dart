import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubit/helper_ratings_cubit.dart';

class RatingStatusWidget extends StatefulWidget {
  final String bookingId;

  const RatingStatusWidget({super.key, required this.bookingId});

  @override
  State<RatingStatusWidget> createState() => _RatingStatusWidgetState();
}

class _RatingStatusWidgetState extends State<RatingStatusWidget> {
  @override
  void initState() {
    super.initState();
    context.read<HelperRatingsCubit>().fetchBookingStatus(widget.bookingId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HelperRatingsCubit, HelperRatingsState>(
      builder: (context, state) {
        if (state is! RatingsLoaded) return const SizedBox();
        
        final status = state.bookingStatuses[widget.bookingId];
        if (status == null) return const SizedBox();

        if (status.canRate && !status.callerHasRated) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () => context.push('/helper/rate-user/${widget.bookingId}'),
              icon: const Icon(Icons.star_outline),
              label: const Text('Rate Tourist'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          );
        }

        if (status.callerHasRated) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
                SizedBox(width: 8),
                Text('You have rated this tourist', style: TextStyle(color: Colors.green, fontSize: 14)),
              ],
            ),
          );
        }

        return const SizedBox();
      },
    );
  }
}
