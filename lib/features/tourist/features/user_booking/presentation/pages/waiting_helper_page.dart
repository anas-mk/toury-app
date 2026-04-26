import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/widgets/custom_button.dart';
import '../../../../../../core/router/app_router.dart';
import '../../domain/entities/booking_detail_entity.dart';
import '../cubits/booking_status_cubit.dart';
import '../cubits/booking_status_state.dart';
import '../cubits/cancel_booking_cubit.dart';
import '../../../../../../core/di/injection_container.dart';

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

class _WaitingHelperPageState extends State<WaitingHelperPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<BookingStatusCubit>()
            ..refreshActiveBooking(widget.bookingId),
        ),
        BlocProvider(create: (_) => sl<CancelBookingCubit>()),
      ],
      child: MultiBlocListener(
        listeners: [
          // Listen for status changes — navigate when helper responds
          BlocListener<BookingStatusCubit, BookingStatusState>(
            listener: (context, state) {
              if (state is BookingStatusActive) {
                final booking = state.booking;
                switch (booking.status) {
                  case BookingStatus.acceptedByHelper:
                    // Move to payment flow
                    context.goNamed(
                      'payment-method',
                      pathParameters: {'bookingId': booking.id},
                    );
                    break;
                  case BookingStatus.confirmedPaid:
                    context.goNamed(
                      'booking-details',
                      pathParameters: {'id': booking.id},
                      extra: {'booking': booking},
                    );
                    break;
                  case BookingStatus.declinedByHelper:
                  case BookingStatus.expiredNoResponse:
                  case BookingStatus.reassignmentInProgress:
                    _showFailedDialog(context, booking);
                    break;
                  default:
                    break;
                }
              }
            },
          ),
          // Listen for cancellation result
          BlocListener<CancelBookingCubit, CancelBookingState>(
            listener: (context, state) {
              if (state is CancelBookingSuccess) {
                context.go(AppRouter.home);
              } else if (state is CancelBookingError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColor.errorColor,
                  ),
                );
              }
            },
          ),
        ],
        child: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spaceLG),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),

                  // Animated radar / pulse
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer ring
                          Transform.scale(
                            scale: _pulseAnimation.value * 1.4,
                            child: Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColor.accentColor.withOpacity(0.08),
                              ),
                            ),
                          ),
                          // Middle ring
                          Transform.scale(
                            scale: _pulseAnimation.value * 1.15,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColor.accentColor.withOpacity(0.14),
                              ),
                            ),
                          ),
                          // Core
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: AppColor.accentColor,
                            child: const Icon(
                              Icons.person_search_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: AppTheme.space2XL),

                  Text(
                    'Waiting for Helper',
                    style: AppTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spaceSM),
                  Text(
                    widget.booking.helper?.name != null
                        ? 'Sending request to ${widget.booking.helper!.name}…'
                        : 'Finding the best available helper…',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColor.lightTextSecondary),
                  ),
                  const SizedBox(height: AppTheme.spaceSM),
                  const Text(
                    'You will be notified as soon as the helper responds.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColor.lightTextSecondary,
                      fontSize: 12,
                    ),
                  ),

                  const Spacer(),

                  // Cancel button — wired to CancelBookingCubit
                  BlocBuilder<CancelBookingCubit, CancelBookingState>(
                    builder: (context, cancelState) {
                      return CustomButton(
                        text: 'Cancel Request',
                        variant: ButtonVariant.outlined,
                        color: AppColor.errorColor,
                        isLoading: cancelState is CancelBookingLoading,
                        onPressed: cancelState is CancelBookingLoading
                            ? null
                            : () => _confirmCancel(context),
                      );
                    },
                  ),
                  const SizedBox(height: AppTheme.spaceXL),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmCancel(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Cancel Request?'),
        content: const Text(
          'Are you sure you want to cancel while waiting for a helper?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Keep Waiting'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<CancelBookingCubit>().cancel(
                widget.bookingId,
                'User cancelled while waiting for helper response.',
              );
            },
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: AppColor.errorColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showFailedDialog(BuildContext context, BookingDetailEntity booking) {
    final isReassigning = booking.status == BookingStatus.reassignmentInProgress;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        title: Text(isReassigning ? 'Finding New Helper' : 'Request Declined'),
        content: Text(
          isReassigning
              ? 'The helper couldn\'t accept. The system is finding another match automatically.'
              : 'The helper is unable to accept at this time. You can view alternatives or go back.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.go(AppRouter.home);
            },
            child: const Text('Back to Home'),
          ),
          if (!isReassigning)
            TextButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                context.pushNamed(
                  'reassignment',
                  pathParameters: {'id': booking.id},
                  extra: {'booking': booking},
                );
              },
              child: const Text('View Alternatives'),
            ),
        ],
      ),
    );
  }
}
