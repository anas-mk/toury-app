import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/widgets/app_network_image.dart';
import '../../../../../../core/widgets/custom_button.dart';
import '../../domain/entities/booking_detail_entity.dart';
import '../cubits/booking_status_cubit.dart';

class WaitingHelperPage extends StatefulWidget {
  final String bookingId;
  final BookingDetailEntity booking;

  const WaitingHelperPage({
    super.key,
    required this.bookingId,
    required this.booking,
  });

  @override
  State<WaitingHelperPage> createState() => _WaitingHelperPageState();
}

class _WaitingHelperPageState extends State<WaitingHelperPage> {
  int _secondsLeft = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        _timer?.cancel();
        // Handle timeout - maybe show alternatives
        context.pushReplacement('/reassignment/${widget.bookingId}', extra: {'booking': widget.booking});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<BookingStatusCubit>()..startPolling(widget.bookingId),
      child: Scaffold(
        body: BlocListener<BookingStatusCubit, BookingStatusState>(
          listener: (context, state) {
            if (state is BookingStatusUpdated) {
              if (state.status.toLowerCase() == 'confirmed') {
                context.go('/booking-details/${widget.bookingId}');
              } else if (state.status.toLowerCase() == 'declined' || state.status.toLowerCase() == 'expired') {
                context.pushReplacement('/reassignment/${widget.bookingId}', extra: {'booking': widget.booking});
              }
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue[900]!, Colors.blue[600]!],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                const Text(
                  'Waiting for Helper...',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'We are notifying the helper about your request.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const Spacer(),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: CircularProgressIndicator(
                        value: _secondsLeft / 60,
                        strokeWidth: 8,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          '$_secondsLeft',
                          style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          'Seconds left',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                if (widget.booking.helper != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: AppNetworkImage(
                      imageUrl: widget.booking.helper!.profileImageUrl ?? '',
                      width: 80,
                      height: 80,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.booking.helper!.name,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${widget.booking.helper!.rating} ★ Helper',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
                const Spacer(),
                CustomButton(
                  text: 'Cancel Request',
                  color: Colors.white,
                  textStyle: const TextStyle(color: Colors.red),
                  onPressed: () {
                    // Call cancel API then pop
                    context.pop();
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
