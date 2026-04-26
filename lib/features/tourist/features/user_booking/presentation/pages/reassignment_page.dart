import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/di/injection_container.dart';
import '../cubits/alternatives_cubit.dart';
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

    return BlocProvider(
      create: (_) => sl<AlternativesCubit>()..loadAlternatives(bookingId),
      child: Scaffold(
        appBar: AppBar(title: const Text('New Helper Needed')),
        body: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Unfortunately, your helper is no longer available. Please select an alternative helper to continue your trip.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: AppTheme.spaceXL),
              Text('Available Alternatives', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppTheme.spaceMD),
              Expanded(
                child: BlocBuilder<AlternativesCubit, AlternativesState>(
                  builder: (context, state) {
                    if (state is AlternativesLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is AlternativesLoaded) {
                      return ListView.builder(
                        itemCount: state.alternatives.length,
                        itemBuilder: (context, index) {
                          final helper = state.alternatives[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: AppTheme.spaceMD),
                            child: ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.person)),
                              title: Text(helper.name),
                              subtitle: Text('${helper.rating} ★ • ${helper.completedTrips} Trips'),
                              trailing: ElevatedButton(
                                onPressed: () {
                                  // Re-book with this helper logic
                                  context.go('/home');
                                },
                                child: const Text('Select'),
                              ),
                            ),
                          );
                        },
                      );
                    }
                    return const Center(child: Text('No alternatives found at this time.'));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
