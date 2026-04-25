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

class _WaitingHelperPageState extends State<WaitingHelperPage> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  int _secondsLeft = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        _timer?.cancel();
        context.pushReplacement('/reassignment/${widget.bookingId}', extra: {'booking': widget.booking});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<BookingStatusCubit>()..startPolling(widget.bookingId),
      child: Scaffold(
        body: BlocListener<BookingStatusCubit, BookingStatusState>(
          listener: (context, state) {
            if (state is BookingActiveFound) {
              final b = state.booking;
              context.go(
                '/user-tracking/${widget.bookingId}?pickupLat=${b.pickupLatitude ?? 0}&pickupLng=${b.pickupLongitude ?? 0}&destLat=${b.destinationLatitude ?? 0}&destLng=${b.destinationLongitude ?? 0}',
              );
            } else if (state is BookingStatusUpdated) {
              final status = state.status.toLowerCase();
              if (status == 'confirmed' || status == 'acceptedbyhelper' || status == 'confirmedpaid') {
                final b = widget.booking;
                context.go(
                  '/user-tracking/${widget.bookingId}?pickupLat=${b.pickupLatitude ?? 0}&pickupLng=${b.pickupLongitude ?? 0}&destLat=${b.destinationLatitude ?? 0}&destLng=${b.destinationLongitude ?? 0}',
                );
              } else if (status == 'declined' || status == 'expired' || status.contains('cancelled')) {
                context.pushReplacement('/reassignment/${widget.bookingId}', extra: {'booking': widget.booking});
              }
            }
          },
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  _buildHeader(),
                  const Spacer(),
                  _buildPulseAnimation(),
                  const Spacer(),
                  _buildHelperCard(),
                  const SizedBox(height: 40),
                  _buildCancelButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Text(
          'Finding your Helper',
          style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Text(
                'Request expires in $_secondsLeft s',
                style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPulseAnimation() {
    return Stack(
      alignment: Alignment.center,
      children: [
        ...List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              double progress = (_pulseController.value + (index / 3)) % 1.0;
              return Container(
                width: 100 + (progress * 200),
                height: 100 + (progress * 200),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.blue.withOpacity(1.0 - progress),
                    width: 2,
                  ),
                ),
              );
            },
          );
        }),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue.withOpacity(0.2),
            boxShadow: [
              BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 40, spreadRadius: 10),
            ],
          ),
          child: const Center(
            child: Icon(Icons.person_search, color: Colors.white, size: 50),
          ),
        ),
      ],
    );
  }

  Widget _buildHelperCard() {
    if (widget.booking.helper == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AppNetworkImage(
              imageUrl: widget.booking.helper!.profileImageUrl ?? '',
              width: 60,
              height: 60,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.booking.helper!.name,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.booking.helper!.rating} • Selected Helper',
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: CustomButton(
        text: 'Cancel Request',
        variant: ButtonVariant.text,
        color: Colors.white.withOpacity(0.5),
        onPressed: () => context.pop(),
      ),
    );
  }
}
