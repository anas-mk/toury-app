import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:toury/features/tourist/features/user_booking/presentation/cubits/booking_state.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/widgets/custom_button.dart';
import '../../../../../../core/router/app_router.dart';
import '../../domain/entities/booking_detail_entity.dart';
import '../cubits/booking_status_cubit.dart';
import '../cubits/booking_status_state.dart';
import '../cubits/booking_cubit.dart';
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

class _WaitingHelperPageState extends State<WaitingHelperPage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BookingStatusCubit>()..startPollingForActive(),
      child: BlocListener<BookingStatusCubit, BookingStatusState>(
        listener: (context, state) {
          if (state is BookingStatusActive) {
            final booking = state.booking;
            if (booking.status == BookingStatus.acceptedByHelper) {
              context.goNamed(
                'payment-method',
                pathParameters: {'bookingId': booking.id},
              );
            } else if (booking.status == BookingStatus.declinedByHelper || booking.status == BookingStatus.expiredNoResponse) {
              _showFailedDialog();
            }
          }
        },
        child: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceLG),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                _buildRadarAnimation(),
                const SizedBox(height: AppTheme.space2XL),
                Text(
                  'Waiting for Helper',
                  style: AppTheme.headlineMedium,
                ),
                const SizedBox(height: AppTheme.spaceSM),
                Text(
                  'Sending request to ${widget.booking.helper?.name ?? "the helper"}...',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColor.lightTextSecondary),
                ),
                const Spacer(),
                BlocProvider(
                  create: (_) => sl<BookingCubit>(),
                  child: BlocBuilder<BookingCubit, BookingState>(
                    builder: (context, state) {
                      return CustomButton(
                        text: 'Cancel Request',
                        variant: ButtonVariant.outlined,
                        color: AppColor.errorColor,
                        isLoading: state is BookingLoading,
                        onPressed: () {
                          context.read<BookingCubit>().cancelBooking(widget.bookingId, 'User cancelled while waiting');
                          context.go(AppRouter.home);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppTheme.spaceXL),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRadarAnimation() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulsing circles (simplified for now with just a static design or simple sized boxes)
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColor.accentColor.withOpacity(0.1),
          ),
        ),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColor.accentColor.withOpacity(0.2),
          ),
        ),
        const CircleAvatar(
          radius: 35,
          backgroundColor: AppColor.accentColor,
          child: Icon(Icons.person_search_rounded, color: Colors.white, size: 35),
        ),
      ],
    );
  }

  void _showFailedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Request Declined'),
        content: const Text('The helper is unable to accept your request at this time. Please try another helper.'),
        actions: [
          TextButton(
            onPressed: () => context.go(AppRouter.home),
            child: const Text('Back to Home'),
          ),
          TextButton(
            onPressed: () => context.go(AppRouter.instantSearch),
            child: const Text('Find Others'),
          ),
        ],
      ),
    );
  }
}
