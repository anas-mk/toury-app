import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/widgets/custom_button.dart';
import '../../../../../../core/widgets/app_network_image.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/router/app_router.dart';
import '../cubits/alternatives_cubit.dart';
import '../cubits/cancel_booking_cubit.dart';
import '../../domain/entities/booking_detail_entity.dart';

class ReassignmentPage extends StatelessWidget {
  final String bookingId;
  final BookingDetailEntity? booking;

  const ReassignmentPage({
    super.key,
    required this.bookingId,
    this.booking,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<AlternativesCubit>()..loadAlternatives(bookingId),
        ),
        BlocProvider(create: (_) => sl<CancelBookingCubit>()),
      ],
      child: BlocListener<CancelBookingCubit, CancelBookingState>(
        listener: (context, state) {
          if (state is CancelBookingSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Booking cancelled successfully.')),
            );
            context.go(AppRouter.home);
          } else if (state is CancelBookingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColor.errorColor),
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('Find Another Helper')),
          body: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceLG),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTheme.spaceMD),
                  decoration: BoxDecoration(
                    color: AppColor.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    border: Border.all(color: AppColor.warningColor.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColor.warningColor),
                      const SizedBox(width: AppTheme.spaceSM),
                      const Expanded(
                        child: Text(
                          'Your original helper is unavailable. Select an alternative or cancel the booking.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spaceXL),

                Text(
                  'Available Alternatives',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppTheme.spaceMD),

                Expanded(
                  child: BlocBuilder<AlternativesCubit, AlternativesState>(
                    builder: (context, state) {
                      if (state is AlternativesLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (state is AlternativesError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: AppColor.errorColor),
                              const SizedBox(height: AppTheme.spaceMD),
                              Text(state.message, textAlign: TextAlign.center),
                              const SizedBox(height: AppTheme.spaceMD),
                              ElevatedButton.icon(
                                onPressed: () => context.read<AlternativesCubit>().loadAlternatives(bookingId),
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }
                      if (state is AlternativesLoaded) {
                        if (state.alternatives.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.person_off_rounded, size: 48, color: AppColor.lightBorder),
                                const SizedBox(height: AppTheme.spaceMD),
                                const Text(
                                  'No alternative helpers available at this time.',
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppTheme.spaceLG),
                                BlocBuilder<CancelBookingCubit, CancelBookingState>(
                                  builder: (context, cancelState) => CustomButton(
                                    text: 'Cancel Booking',
                                    variant: ButtonVariant.outlined,
                                    color: AppColor.errorColor,
                                    isLoading: cancelState is CancelBookingLoading,
                                    onPressed: () => _showCancelDialog(context),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return ListView.separated(
                          itemCount: state.alternatives.length,
                          separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spaceMD),
                          itemBuilder: (context, index) {
                            final helper = state.alternatives[index];
                            return Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                                side: const BorderSide(color: AppColor.lightBorder),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(AppTheme.spaceMD),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                                      child: AppNetworkImage(
                                        imageUrl: helper.profileImageUrl ?? '',
                                        width: 52,
                                        height: 52,
                                      ),
                                    ),
                                    const SizedBox(width: AppTheme.spaceMD),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            helper.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          Row(
                                            children: [
                                              const Icon(Icons.star_rounded, size: 13, color: Colors.amber),
                                              const SizedBox(width: 3),
                                              Text(
                                                '${helper.rating.toStringAsFixed(1)} • ${helper.completedTrips} trips',
                                                style: const TextStyle(fontSize: 12, color: AppColor.lightTextSecondary),
                                              ),
                                            ],
                                          ),
                                          if (helper.estimatedPrice != null)
                                            Text(
                                              '~${helper.estimatedPrice!.toStringAsFixed(0)} EGP',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColor.accentColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => context.pushNamed(
                                        'helper-profile',
                                        pathParameters: {'id': helper.id},
                                        extra: {
                                          'helper': helper,
                                          'searchParams': null,
                                          'isInstant': false,
                                        },
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColor.primaryColor,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                                        ),
                                      ),
                                      child: const Text('Select'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason:'),
            const SizedBox(height: 8),
            TextField(
              controller: reasonCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'e.g. No suitable alternative found',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Back')),
          TextButton(
            onPressed: () {
              final reason = reasonCtrl.text.trim();
              if (reason.length < 5) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reason must be at least 5 characters.')),
                );
                return;
              }
              Navigator.pop(dialogCtx);
              context.read<CancelBookingCubit>().cancel(bookingId, reason);
            },
            child: const Text('Confirm Cancel', style: TextStyle(color: AppColor.errorColor)),
          ),
        ],
      ),
    );
  }
}
