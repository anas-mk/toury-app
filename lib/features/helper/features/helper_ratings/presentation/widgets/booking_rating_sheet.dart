import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toury/features/helper/features/helper_ratings/presentation/pages/rate_user_page.dart';
import '../../../../../../core/di/injection_container.dart';
import '../cubit/helper_ratings_cubits.dart';

class BookingRatingSheet extends StatefulWidget {
  final String bookingId;
  final String travelerName;
  final String travelerAvatar;

  const BookingRatingSheet({
    super.key,
    required this.bookingId,
    required this.travelerName,
    required this.travelerAvatar,
  });

  @override
  State<BookingRatingSheet> createState() => _BookingRatingSheetState();
}

class _BookingRatingSheetState extends State<BookingRatingSheet> {
  late final BookingRatingStateCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<BookingRatingStateCubit>()..loadState(widget.bookingId);
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
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF141829),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: BlocBuilder<BookingRatingStateCubit, BookingRatingState>(
          builder: (context, state) {
            if (state is BookingRatingLoading) {
              return const SizedBox(
                height: 150,
                child: Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF))),
              );
            } else if (state is BookingRatingLoaded) {
              final s = state.stateEntity;
              if (s.canRate) {
                return _buildRateAction(context);
              } else if (s.callerHasRated) {
                return _buildAlreadyRated();
              } else {
                return _buildWaitingState();
              }
            } else if (state is BookingRatingError) {
              return _buildErrorState(state.message);
            }
            return const SizedBox(height: 150);
          },
        ),
      ),
    );
  }

  Widget _buildRateAction(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Rate your Traveler',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'How was your trip with ${widget.travelerName}?',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white38, fontSize: 14),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () async {
              final rated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RateUserPage(
                    bookingId: widget.bookingId,
                    travelerName: widget.travelerName,
                    travelerAvatar: widget.travelerAvatar,
                  ),
                ),
              );
              if (rated == true) {
                _cubit.loadState(widget.bookingId);
              }
            },
            icon: const Icon(Icons.star_rounded, color: Colors.white),
            label: const Text(
              'Rate Traveler',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildAlreadyRated() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_rounded, color: Color(0xFF00C896), size: 48),
        const SizedBox(height: 16),
        const Text(
          'Thank you!',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'You have already rated this traveler.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white38, fontSize: 14),
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Dismiss', style: TextStyle(color: Color(0xFF6C63FF))),
        ),
      ],
    );
  }

  Widget _buildWaitingState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.timer_outlined, color: Colors.amber, size: 48),
        const SizedBox(height: 16),
        const Text(
          'Trip not completed',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'You can rate the traveler after the trip is marked as completed.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white38, fontSize: 14),
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Dismiss', style: TextStyle(color: Color(0xFF6C63FF))),
        ),
      ],
    );
  }

  Widget _buildErrorState(String message) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, color: Color(0xFFFF6B6B), size: 48),
        const SizedBox(height: 16),
        const Text(
          'Oops!',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white38, fontSize: 14),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => _cubit.loadState(widget.bookingId),
          child: const Text('Retry'),
        ),
      ],
    );
  }
}
